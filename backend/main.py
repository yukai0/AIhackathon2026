from __future__ import annotations

import json
import os
from datetime import date
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

load_dotenv()

from models import MenuItem, MealPlan, PlanRequest
from planner import generate_plan
from scraper import scrape_menu

CACHE_DIR = Path(__file__).parent / "cache"
DEMO_MODE = os.getenv("DEMO_MODE", "false").lower() == "true"
DEMO_CACHE_FILE = CACHE_DIR / "menu_demo.json"

app = FastAPI(title="BearFuel API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def _load_menu_cache(target_date: str, location: str | None = None) -> dict:
    if DEMO_MODE:
        cache_file = DEMO_CACHE_FILE
    else:
        cache_file = CACHE_DIR / f"menu_{target_date}.json"
        if not cache_file.exists():
            # Fall back to demo seed if no live cache
            cache_file = DEMO_CACHE_FILE

    if not cache_file.exists():
        raise HTTPException(status_code=503, detail="Menu cache not available")

    with open(cache_file) as f:
        data = json.load(f)

    if location and location != "all":
        data["items"] = [
            item for item in data.get("items", [])
            if item.get("location", "").lower() == location.lower()
        ]

    return data


@app.get("/health")
async def health():
    demo_cache_exists = DEMO_CACHE_FILE.exists()
    today = date.today().isoformat()
    live_cache_exists = (CACHE_DIR / f"menu_{today}.json").exists()
    return {
        "status": "ok",
        "demo_mode": DEMO_MODE,
        "demo_cache": demo_cache_exists,
        "live_cache_today": live_cache_exists,
        "date": today,
    }


@app.get("/menu", response_model=list[MenuItem])
async def get_menu(
    menu_date: str = Query(default="today", alias="date"),
    location: str = Query(default="all"),
):
    from datetime import date as _date
    target_date = _date.today().isoformat() if menu_date == "today" else menu_date

    # If live cache is missing for this date, try a live scrape (unless DEMO_MODE)
    if not DEMO_MODE:
        cache_file = CACHE_DIR / f"menu_{target_date}.json"
        if not cache_file.exists():
            import asyncio, logging
            logging.getLogger(__name__).info("No cache for %s — triggering scrape", target_date)
            await asyncio.get_event_loop().run_in_executor(None, scrape_menu, target_date)

    data = _load_menu_cache(target_date, location if location != "all" else None)
    items = data.get("items", [])
    return [MenuItem(**item) for item in items]


@app.post("/scrape")
async def trigger_scrape(menu_date: str = Query(default="today", alias="date")):
    """Admin endpoint to populate the menu cache for a given date."""
    from datetime import date as _date
    import asyncio
    target_date = _date.today().isoformat() if menu_date == "today" else menu_date
    items = await asyncio.get_event_loop().run_in_executor(None, scrape_menu, target_date)
    return {
        "scraped": len(items),
        "locations": list({i.location for i in items}),
        "date": target_date,
    }


@app.post("/plan", response_model=MealPlan)
async def create_plan(request: PlanRequest):
    from datetime import date as _date
    target_date = request.date if request.date else _date.today().isoformat()

    # Load menu from cache
    data = _load_menu_cache(target_date)
    all_items = [MenuItem(**item) for item in data.get("items", [])]

    plan = await generate_plan(request.profile, all_items, target_date)
    return plan
