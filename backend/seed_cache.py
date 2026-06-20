#!/usr/bin/env python3
"""
Copy the demo seed to today's dated cache file, useful when running
the backend without a live scrape or in DEMO_MODE=false environments.

Usage: python seed_cache.py
"""
import json
import shutil
from datetime import date
from pathlib import Path

CACHE_DIR = Path(__file__).parent / "cache"
DEMO_FILE = CACHE_DIR / "menu_demo.json"


def seed_today() -> None:
    today = date.today().isoformat()
    dest = CACHE_DIR / f"menu_{today}.json"
    with open(DEMO_FILE) as f:
        data = json.load(f)
    data["date"] = today
    data["source"] = "seed_demo"
    with open(dest, "w") as f:
        json.dump(data, f, indent=2)
    print(f"Seeded {dest}")


if __name__ == "__main__":
    seed_today()
