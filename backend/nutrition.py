"""
NutritionFallback: Claude-estimated macros for dishes missing a scraped nutrition block.
This module is rarely called — real Berkeley dining data covers nearly every item.
Results are disk-cached by dish name and always flagged estimated=true.
"""
from __future__ import annotations

import json
import os
from pathlib import Path

import anthropic

from models import NutritionInfo

_FALLBACK_CACHE_FILE = Path(__file__).parent / "cache" / "nutrition_fallback_cache.json"
MODEL = os.getenv("ANTHROPIC_MODEL", "claude-sonnet-4-6")


def _load_fallback_cache() -> dict:
    if _FALLBACK_CACHE_FILE.exists():
        with open(_FALLBACK_CACHE_FILE) as f:
            return json.load(f)
    return {}


def _save_fallback_cache(cache: dict) -> None:
    with open(_FALLBACK_CACHE_FILE, "w") as f:
        json.dump(cache, f, indent=2)


async def estimate_nutrition(dish_name: str, serving_desc: str = "") -> NutritionInfo:
    cache = _load_fallback_cache()
    key = f"{dish_name}|{serving_desc}"
    if key in cache:
        data = cache[key]
        return NutritionInfo(**data)

    client = anthropic.AsyncAnthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    prompt = (
        f"Estimate the nutrition facts for: {dish_name}"
        + (f" (serving: {serving_desc})" if serving_desc else "")
        + "\n\nRespond ONLY with a JSON object with keys: "
        "kcal, protein_g, carb_g, fat_g, fiber_g, sugar_g, sodium_mg. "
        "Use typical values for a university dining hall preparation."
    )

    try:
        response = await client.messages.create(
            model=MODEL,
            max_tokens=256,
            timeout=15.0,
            messages=[{"role": "user", "content": prompt}],
        )
        raw = response.content[0].text.strip()
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
        data = json.loads(raw)
        nutrition = NutritionInfo(
            kcal=float(data.get("kcal", 200)),
            protein_g=float(data.get("protein_g", 8)),
            carb_g=float(data.get("carb_g", 25)),
            fat_g=float(data.get("fat_g", 7)),
            fiber_g=float(data.get("fiber_g", 2)),
            sugar_g=float(data.get("sugar_g", 3)),
            sodium_mg=float(data.get("sodium_mg", 300)),
            estimated=True,
            confidence="low",
        )
        cache[key] = nutrition.model_dump()
        _save_fallback_cache(cache)
        return nutrition
    except Exception:
        return NutritionInfo(
            kcal=200, protein_g=8, carb_g=25, fat_g=7,
            estimated=True, confidence="low"
        )
