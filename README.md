# BearFuel — Berkeley AI Hackathon 2026

**The wedge:** UC Berkeley freshmen eat on a meal plan, have free gym access, and don't cook. The single highest-leverage nutrition intervention is *"tell me what to put on my tray at Crossroads tonight."* Generic meal-plan apps can't do this. BearFuel can.

## What it does

BearFuel takes a student's stats and body-composition goal, pulls today's real Berkeley dining-hall menu (with actual USDA-derived nutrition per dish), and uses **Claude** to assemble a personalized meal plan from dishes that are actually being served — hitting their calorie and protein targets.

## The data insight (key technical story)

Berkeley dining embeds full USDA-derived nutrition facts for every dish in their menu system. The `data-location` attributes in the page HTML are base64-encoded paths to public XML files:

```
https://dining.berkeley.edu/wp-content/uploads/menus-exportimport/{Location}_{YYYYMMDD}.xml
```

Each XML is `EatecExchange` format with structured nutrition for every recipe (kcal, protein, carb, fat, fiber, sugar, sodium, …). **One HTTP request per location per day gives every dish with complete USDA-derived nutrition** — no AJAX, no per-item API calls, no estimation.

Verified against the Berkeley site: Cinnamon Raisin Bagels → 250.83 kcal, 8.05g protein, 50.14g carb, 1.34g fat ✓

## Architecture

```
┌──────────────────┐     HTTPS/JSON      ┌─────────────────────────┐    Anthropic API
│  SwiftUI iOS app │  <───────────────>  │  FastAPI backend         │  <──────────────>  Claude
│  (the client)    │                     │  scraper + planner + AI  │
└──────────────────┘                     └─────────────────────────┘
```

- **API key lives only in the backend.** The iOS app never sees it.
- **Cache-first:** scraper writes `cache/menu_{date}.json`; endpoints read from cache. No live scrape at request time.
- **Demo-safe:** `DEMO_MODE=true` serves `cache/menu_demo.json` (committed seed). iOS app bundles `demo_plan.json` as fallback if backend is unreachable.

## Running locally

### Backend

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Copy and fill in your API key
cp .env.example .env
# Edit .env: ANTHROPIC_API_KEY=sk-ant-...

# Option A: demo mode (no live scrape)
DEMO_MODE=true uvicorn main:app --reload --port 8002

# Option B: live mode (scrapes today's menu on first /menu request)
uvicorn main:app --reload --port 8002

# Or pre-seed the cache manually
python seed_cache.py      # copies demo seed to today's date
python scraper.py         # scrapes live Berkeley data for today
```

Verify:
```bash
curl http://localhost:8002/health
curl "http://localhost:8002/menu?date=today&location=Crossroads" | python3 -m json.tool | head -30
curl -X POST http://localhost:8002/plan \
  -H 'Content-Type: application/json' \
  -d '{"profile":{"height_cm":178,"weight_kg":75,"age":19,"sex":"male","activity_level":"moderate","goal_type":"lean_gain","meals_per_day":3,"diet_restrictions":[],"exclude_allergens":[],"preferred_locations":["Crossroads"]},"date":"today"}'
```

### iOS

```bash
cd ios
# Install XcodeGen if needed: brew install xcodegen
xcodegen generate    # produces BearFuel.xcodeproj
open BearFuel.xcodeproj
```

- Set `Config.swift` `baseURL` to your backend URL
- Build and run on Simulator (iOS 17+)
- The app loads `demo_plan.json` from the bundle if the backend is unreachable

## Health & safety guardrails

All enforced in `backend/planner.py` — never delegated to the model:

| Guardrail | Implementation |
|-----------|---------------|
| Calorie floor | ≥1500 kcal/day (men), ≥1200 (women); clamped with user-visible note |
| Deficit cap | Max −20% below TDEE |
| Surplus cap | Max +10% above TDEE |
| Low BMI guard | BMI < 17.5 → switch to maintenance + link to Berkeley dietitian |
| Input validation | Height/weight/age range checks via Pydantic |
| Framing | Language is fueling/energy/habits — no weight loss imagery |
| Disclaimer | Always shown on every plan |

## Sponsor context (Anthropic / Claude)

Claude is the headline capability: given 200+ real Berkeley dining-hall dishes with USDA nutrition, it composes a day's meals that hit a personalized calorie/protein target under dietary, allergen, and location constraints — something no static macro calculator can do. The server recomputes all totals from real nutrition data after Claude selects dishes, so the numbers are always accurate.

Model: `claude-sonnet-4-6` (configurable via `ANTHROPIC_MODEL` in `.env`).
