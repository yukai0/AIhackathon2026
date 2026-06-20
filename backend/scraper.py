"""
Berkeley Dining scraper.

Discovery: fetch the main /menus/ page, extract data-location base64 attributes
→ decode to XML file paths → fetch each XML.

Data: each XML is EatecExchange format with full USDA-derived nutrition for every
recipe in pipe-delimited <nutrients> attrs. One request per location gives every
dish + macro for a given date. No AJAX, no N+1 calls, no estimation needed.
"""
from __future__ import annotations

import base64
import hashlib
import json
import logging
import re
from datetime import date as _date
from pathlib import Path
from typing import Optional
from xml.etree import ElementTree as ET

import requests

from models import MenuItem, NutritionInfo

logger = logging.getLogger(__name__)

CACHE_DIR = Path(__file__).parent / "cache"
BASE_URL = "https://dining.berkeley.edu"
MENUS_PAGE = f"{BASE_URL}/menus/"
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0 Safari/537.36"
    )
}

# Allergen <allergen id="..."> → our model key
ALLERGEN_MAP: dict[str, str] = {
    "Milk": "milk",
    "Egg": "egg",
    "Fish": "fish",
    "Shellfish": "shellfish",
    "Tree Nuts": "treenut",
    "Wheat": "wheat",
    "Peanuts": "peanut",
    "Soybeans": "soy",
    "Gluten": "gluten",
    "Alcohol": "alcohol",
    "Sesame": "sesame",
    "Pork": "pork",
}

# <dietaryChoice id="..."> → our model key
DIET_FLAG_MAP: dict[str, str] = {
    "Vegan Option": "vegan",
    "Vegetarian Option": "vegetarian",
    "Halal": "halal",
    "Kosher": "kosher",
}

# Normalize meal period names (may contain season prefix like "Summer - Dinner")
def _normalize_meal_period(raw: str) -> str:
    raw_lower = raw.lower()
    if "breakfast" in raw_lower or "brunch" in raw_lower:
        return "Brunch"
    if "lunch" in raw_lower:
        return "Lunch"
    if "dinner" in raw_lower:
        return "Dinner"
    return "All Day"


def _carbon_tier(kg_co2: Optional[float]) -> Optional[str]:
    if kg_co2 is None:
        return None
    if kg_co2 <= 0.08:
        return "low"
    if kg_co2 <= 0.20:
        return "medium"
    return "high"


def _make_id(name: str, station: str, location: str, target_date: str) -> str:
    key = f"{name}|{station}|{location}|{target_date}"
    return hashlib.md5(key.encode()).hexdigest()[:16]


def _discover_xml_urls(target_date: str) -> list[str]:
    """
    Fetch the /menus/ page and decode the data-location base64 attributes
    to obtain the list of XML URLs for the given date.
    """
    try:
        r = requests.get(MENUS_PAGE, headers=HEADERS, timeout=20)
        r.raise_for_status()
    except Exception as e:
        logger.error("Failed to fetch menus page: %s", e)
        return _fallback_xml_urls(target_date)

    locations_b64 = re.findall(r'data-location=["\']([A-Za-z0-9+/=]+)["\']', r.text)
    urls: set[str] = set()
    for b64 in set(locations_b64):
        try:
            path = base64.b64decode(b64 + "==").decode()
            # Strip the internal /code prefix and build the public URL
            url_path = path.replace("/code", "")
            urls.add(BASE_URL + url_path)
        except Exception:
            continue

    if not urls:
        logger.warning("No XML URLs discovered from menu page; using fallback list")
        return _fallback_xml_urls(target_date)

    return sorted(urls)


def _fallback_xml_urls(target_date: str) -> list[str]:
    """Known location names when discovery fails."""
    date_str = target_date.replace("-", "")
    known_locations = ["Crossroads", "ClarkKerr", "Foothill", "Den", "Unit1"]
    base_path = f"{BASE_URL}/wp-content/uploads/menus-exportimport"
    urls = []
    for loc in known_locations:
        url = f"{base_path}/{loc}_{date_str}.xml"
        try:
            r = requests.head(url, headers=HEADERS, timeout=5)
            if r.status_code == 200:
                urls.append(url)
        except Exception:
            continue
    return urls


def _parse_nutrient_cols(menu_elem: ET.Element) -> list[str]:
    nutrients_elem = menu_elem.find("nutrients")
    if nutrients_elem is None or not nutrients_elem.text:
        return []
    return [c.strip() for c in nutrients_elem.text.split("|") if c.strip()]


MAX_SANE_KCAL = 2500   # single serving above this is a data entry error
MAX_NAME_LEN = 80      # longer names are usually venue descriptions, not dishes


def _parse_recipe(
    recipe_elem: ET.Element,
    nutrient_cols: list[str],
    location: str,
    meal_period: str,
    target_date: str,
) -> Optional[MenuItem]:
    name = recipe_elem.get("shortName", "").strip()
    if not name:
        name = recipe_elem.get("description", "").strip()
    if not name:
        return None

    # Skip venue blurbs (descriptions masquerading as recipes)
    if len(name) > MAX_NAME_LEN:
        return None

    station = recipe_elem.get("category", "").strip()
    serving_size = recipe_elem.get("servingSize", "")
    serving_unit = recipe_elem.get("servingSizeUnit", "")
    serving_desc = f"{serving_size} {serving_unit}".strip() if serving_size else ""

    # Parse pipe-delimited nutrient values
    raw_nutrients = recipe_elem.get("nutrients", "")
    vals = raw_nutrients.split("|")

    def _val(col_name: str) -> float:
        try:
            idx = next(i for i, c in enumerate(nutrient_cols) if col_name in c)
            v = vals[idx] if idx < len(vals) else ""
            return float(v) if v else 0.0
        except (StopIteration, ValueError):
            return 0.0

    kcal = _val("Calories")
    fat_g = _val("Total Lipid")
    sat_fat_g = _val("Saturated fatty")
    trans_fat_g = _val("Trans Fat")
    cholesterol_mg = _val("Cholesterol")
    sodium_mg = _val("Sodium")
    carb_g = _val("Carbohydrate")
    fiber_g = _val("Dietary Fiber")
    sugar_g = _val("Sugar")
    protein_g = _val("Protein")
    carbon_kg = _val("Carbon Footprint")

    # Allergens
    allergens: list[str] = []
    for allergen_elem in recipe_elem.findall("allergens/allergen"):
        if allergen_elem.text and allergen_elem.text.strip() == "Yes":
            key = ALLERGEN_MAP.get(allergen_elem.get("id", ""))
            if key:
                allergens.append(key)

    # Dietary choices
    diet_flags: list[str] = []
    for dc_elem in recipe_elem.findall("dietaryChoices/dietaryChoice"):
        if dc_elem.text and dc_elem.text.strip() == "Yes":
            key = DIET_FLAG_MAP.get(dc_elem.get("id", ""))
            if key:
                diet_flags.append(key)

    # Skip items with clearly erroneous serving-size bulk entries
    if kcal > MAX_SANE_KCAL:
        logger.debug("Skipping '%s' — kcal %.0f exceeds sane threshold (bulk serving?)", name, kcal)
        return None

    # Zero-kcal items get flagged for NutritionFallback in planner.py
    needs_estimate = (kcal == 0 and protein_g == 0 and carb_g == 0)

    item_id = _make_id(name, station, location, target_date)

    return MenuItem(
        id=item_id,
        name=name,
        station=station,
        location=location,
        meal_period=meal_period,  # type: ignore[arg-type]
        date=target_date,
        diet_flags=diet_flags,  # type: ignore[arg-type]
        allergens=allergens,  # type: ignore[arg-type]
        carbon=_carbon_tier(carbon_kg if carbon_kg > 0 else None),
        carbon_kg_co2=carbon_kg if carbon_kg > 0 else None,
        serving_desc=serving_desc,
        nutrition=NutritionInfo(
            kcal=kcal,
            protein_g=protein_g,
            carb_g=carb_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            sugar_g=sugar_g,
            sodium_mg=sodium_mg,
            sat_fat_g=sat_fat_g,
            trans_fat_g=trans_fat_g,
            cholesterol_mg=cholesterol_mg,
            estimated=needs_estimate,
            confidence="low" if needs_estimate else "high",
        ),
    )


def _parse_xml(xml_text: str, target_date: str) -> list[MenuItem]:
    """Parse an EatecExchange XML and return all MenuItems."""
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError as e:
        logger.error("XML parse error: %s", e)
        return []

    items: list[MenuItem] = []
    for menu_elem in root.findall("menu"):
        location = menu_elem.get("location", "Unknown")
        raw_period = menu_elem.get("mealperiodname", "")
        meal_period = _normalize_meal_period(raw_period)
        nutrient_cols = _parse_nutrient_cols(menu_elem)

        for recipe_elem in menu_elem.findall("recipes/recipe"):
            item = _parse_recipe(recipe_elem, nutrient_cols, location, meal_period, target_date)
            if item is not None:
                items.append(item)

    return items


def scrape_menu(target_date: Optional[str] = None) -> list[MenuItem]:
    """
    Fetch all Berkeley dining XMLs for the given date, parse them,
    write a normalized cache file, and return the list of MenuItems.
    """
    if target_date is None:
        target_date = _date.today().isoformat()

    logger.info("Scraping menu for %s", target_date)
    xml_urls = _discover_xml_urls(target_date)
    logger.info("Discovered %d XML files: %s", len(xml_urls), xml_urls)

    all_items: list[MenuItem] = []
    for url in xml_urls:
        try:
            r = requests.get(url, headers=HEADERS, timeout=20)
            r.raise_for_status()
            items = _parse_xml(r.text, target_date)
            logger.info("  %s → %d items", url.split("/")[-1], len(items))
            all_items.extend(items)
        except Exception as e:
            logger.warning("Failed to fetch %s: %s", url, e)

    if not all_items:
        logger.error("No items scraped; returning empty list")
        return []

    # Write cache
    CACHE_DIR.mkdir(exist_ok=True)
    cache_file = CACHE_DIR / f"menu_{target_date}.json"
    cache_data = {
        "date": target_date,
        "scraped_at": _date.today().isoformat() + "T00:00:00Z",
        "source": "live_scrape",
        "locations": sorted({item.location for item in all_items}),
        "items": [item.model_dump() for item in all_items],
    }
    with open(cache_file, "w") as f:
        json.dump(cache_data, f, indent=2)
    logger.info("Wrote %d items to %s", len(all_items), cache_file)

    return all_items


if __name__ == "__main__":
    import sys
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    target = sys.argv[1] if len(sys.argv) > 1 else None
    items = scrape_menu(target)
    print(f"\nScraped {len(items)} items across {len({i.location for i in items})} locations")
    for item in items[:5]:
        print(f"  {item.location} | {item.meal_period} | {item.name} | {item.nutrition.kcal} kcal / {item.nutrition.protein_g}g protein")
