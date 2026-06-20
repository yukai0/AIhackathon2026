from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Optional

import anthropic

from models import (
    ActivityLevel, GoalType, MealPlan, MacroTargets, MacroTotals,
    MealSlot, MenuItem, Sex, UserProfile, HealthWarning
)

_client: Optional[anthropic.AsyncAnthropic] = None

PROMPTS_DIR = Path(__file__).parent / "prompts"
MODEL = os.getenv("ANTHROPIC_MODEL", "claude-sonnet-4-6")

ACTIVITY_MULTIPLIERS: dict[ActivityLevel, float] = {
    "sedentary": 1.2,
    "light": 1.375,
    "moderate": 1.55,
    "active": 1.725,
    "very_active": 1.9,
}

CALORIE_FLOORS = {"male": 1500.0, "female": 1200.0, "unspecified": 1350.0}
MAX_DEFICIT_PCT = 0.20
MAX_SURPLUS_PCT = 0.10
LOW_BMI_THRESHOLD = 17.5

MEAL_LABELS_BY_COUNT = {
    1: ["Dinner"],
    2: ["Brunch", "Dinner"],
    3: ["Brunch", "Lunch", "Dinner"],
    4: ["Brunch", "Lunch", "Dinner", "Late Snack"],
}


def _get_client() -> anthropic.AsyncAnthropic:
    global _client
    if _client is None:
        _client = anthropic.AsyncAnthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    return _client


def compute_bmr(profile: UserProfile) -> float:
    if profile.sex == "male":
        return 10 * profile.weight_kg + 6.25 * profile.height_cm - 5 * profile.age + 5
    elif profile.sex == "female":
        return 10 * profile.weight_kg + 6.25 * profile.height_cm - 5 * profile.age - 161
    else:
        return 10 * profile.weight_kg + 6.25 * profile.height_cm - 5 * profile.age - 78


def compute_targets(profile: UserProfile) -> tuple[MacroTargets, list[HealthWarning]]:
    warnings: list[HealthWarning] = []

    bmr = compute_bmr(profile)
    tdee = bmr * ACTIVITY_MULTIPLIERS[profile.activity_level]
    bmi = profile.weight_kg / ((profile.height_cm / 100) ** 2)

    # Low BMI guard: do not allow deficit plans
    if bmi < LOW_BMI_THRESHOLD and profile.goal_type == "cut":
        warnings.append(HealthWarning(
            code="low_bmi_cut_blocked",
            message=(
                "Your BMI suggests you should not be in a calorie deficit. "
                "We've switched to a maintenance plan. Please consider speaking with "
                "a Berkeley campus dietitian: https://dining.berkeley.edu/dietitian/"
            ),
            severity="warning",
        ))
        profile = profile.model_copy(update={"goal_type": "maintain"})

    goal_adjustments: dict[GoalType, float] = {
        "cut": -0.175,
        "maintain": 0.0,
        "lean_gain": 0.075,
        "recomp": 0.0,
        "athletic_performance": 0.10,
    }
    adj = goal_adjustments[profile.goal_type]

    # Clamp adjustments to safety bounds
    if adj < -MAX_DEFICIT_PCT:
        adj = -MAX_DEFICIT_PCT
    if adj > MAX_SURPLUS_PCT:
        adj = MAX_SURPLUS_PCT

    target_kcal = tdee * (1 + adj)

    # Calorie floor enforcement
    floor = CALORIE_FLOORS.get(profile.sex, 1350.0)
    if target_kcal < floor:
        warnings.append(HealthWarning(
            code="calorie_floor_clamped",
            message=f"Calorie target was below the minimum safe level ({floor:.0f} kcal). Plan adjusted.",
            severity="info",
        ))
        target_kcal = floor

    # Protein target: 1.6–2.2 g/kg (higher end for lean_gain/athletic)
    protein_multiplier = 2.0 if profile.goal_type in ("lean_gain", "athletic_performance") else 1.8
    target_protein = profile.weight_kg * protein_multiplier
    target_fat = target_kcal * 0.28 / 9
    target_carb = (target_kcal - (target_protein * 4) - (target_fat * 9)) / 4

    if target_carb < 50:
        target_carb = 50.0

    return MacroTargets(
        kcal=round(target_kcal, 1),
        protein_g=round(target_protein, 1),
        carb_g=round(target_carb, 1),
        fat_g=round(target_fat, 1),
    ), warnings


def _filter_items(items: list[MenuItem], profile: UserProfile) -> list[MenuItem]:
    filtered = items
    if profile.preferred_locations:
        locs_lower = {loc.lower() for loc in profile.preferred_locations}
        filtered = [i for i in filtered if i.location.lower() in locs_lower]
        if not filtered:
            filtered = items  # don't produce empty set

    if profile.diet_restrictions:
        flags = set(profile.diet_restrictions)
        filtered = [
            i for i in filtered
            if not flags or flags.intersection(set(i.diet_flags))
        ]

    if profile.exclude_allergens:
        excluded = set(profile.exclude_allergens)
        filtered = [i for i in filtered if not excluded.intersection(set(i.allergens))]

    return filtered


def _load_system_prompt() -> str:
    prompt_file = PROMPTS_DIR / "planner_system.txt"
    if prompt_file.exists():
        return prompt_file.read_text()
    return (
        "You are a nutrition expert helping UC Berkeley students eat toward their "
        "body-composition goals using only food available in campus dining halls today. "
        "You select real dining-hall dishes to hit calorie and protein targets. "
        "Always respond with valid JSON only, no prose."
    )


def _build_user_prompt(
    profile: UserProfile,
    targets: MacroTargets,
    candidates: list[MenuItem],
    target_date: str,
    meal_labels: list[str],
) -> str:
    items_payload = [
        {
            "id": item.id,
            "name": item.name,
            "station": item.station,
            "location": item.location,
            "meal_period": item.meal_period,
            "diet_flags": item.diet_flags,
            "serving_desc": item.serving_desc,
            "nutrition": {
                "kcal": item.nutrition.kcal,
                "protein_g": item.nutrition.protein_g,
                "carb_g": item.nutrition.carb_g,
                "fat_g": item.nutrition.fat_g,
                "fiber_g": item.nutrition.fiber_g,
            },
        }
        for item in candidates
    ]

    return f"""
Date: {target_date}
Student goal: {profile.goal_type}
Daily targets: {targets.kcal:.0f} kcal | {targets.protein_g:.0f}g protein | {targets.carb_g:.0f}g carbs | {targets.fat_g:.0f}g fat
Meals needed: {meal_labels}
Diet restrictions: {profile.diet_restrictions or 'none'}
Allergens to avoid: {profile.exclude_allergens or 'none'}
Preferred locations: {profile.preferred_locations or 'any'}

Available dining hall dishes (with full nutrition from Berkeley dining website):
{json.dumps(items_payload, indent=2)}

Select dishes for each meal from the list above. Requirements:
1. Only use dish IDs from the provided list — do not invent items.
2. Day totals should land within ±10% of each macro target.
3. Spread protein roughly evenly across meals.
4. For each meal, pick 1–4 complementary dishes from the same location if possible.
5. Add a one-sentence rationale for each meal.

Respond ONLY with a JSON object matching this schema (no markdown, no prose):
{{
  "meals": [
    {{
      "label": "<meal label>",
      "location": "<dining hall name>",
      "items": ["<dish id>", ...],
      "totals": {{"kcal": 0, "protein_g": 0, "carb_g": 0, "fat_g": 0}},
      "rationale": "<one sentence>"
    }}
  ],
  "notes": "<overall notes about the plan>"
}}
"""


def _greedy_fallback(
    targets: MacroTargets,
    candidates: list[MenuItem],
    meal_labels: list[str],
) -> MealPlan:
    """Deterministic greedy selector — used when Claude fails twice."""
    # Sort by protein density to prioritize protein-dense items
    sorted_items = sorted(
        candidates, key=lambda x: x.nutrition.protein_g / max(x.nutrition.kcal, 1), reverse=True
    )

    remaining_kcal = targets.kcal
    remaining_protein = targets.protein_g
    per_meal_kcal = targets.kcal / len(meal_labels)
    per_meal_protein = targets.protein_g / len(meal_labels)

    meals: list[MealSlot] = []
    used_ids: set[str] = set()

    # Group by location for coherent meals
    locations = list({item.location for item in candidates})
    if not locations:
        locations = ["Crossroads"]

    for i, label in enumerate(meal_labels):
        loc = locations[i % len(locations)]
        loc_items = [x for x in sorted_items if x.location == loc and x.id not in used_ids]
        if not loc_items:
            loc_items = [x for x in sorted_items if x.id not in used_ids]

        meal_items: list[MenuItem] = []
        meal_kcal = 0.0
        meal_protein = 0.0
        meal_carb = 0.0
        meal_fat = 0.0

        for item in loc_items:
            if meal_kcal + item.nutrition.kcal > per_meal_kcal * 1.3:
                continue
            meal_items.append(item)
            meal_kcal += item.nutrition.kcal
            meal_protein += item.nutrition.protein_g
            meal_carb += item.nutrition.carb_g
            meal_fat += item.nutrition.fat_g
            used_ids.add(item.id)
            if len(meal_items) >= 3:
                break

        if not meal_items and sorted_items:
            item = sorted_items[0]
            meal_items = [item]
            meal_kcal = item.nutrition.kcal
            meal_protein = item.nutrition.protein_g
            meal_carb = item.nutrition.carb_g
            meal_fat = item.nutrition.fat_g

        meals.append(MealSlot(
            label=label,
            location=loc,
            items=[m.id for m in meal_items],
            totals=MacroTotals(
                kcal=round(meal_kcal, 1),
                protein_g=round(meal_protein, 1),
                carb_g=round(meal_carb, 1),
                fat_g=round(meal_fat, 1),
            ),
            rationale="Automatically selected to meet macro targets.",
        ))

    day_kcal = sum(m.totals.kcal for m in meals)
    day_protein = sum(m.totals.protein_g for m in meals)
    day_carb = sum(m.totals.carb_g for m in meals)
    day_fat = sum(m.totals.fat_g for m in meals)

    return MealPlan(
        date="",
        targets=targets,
        meals=meals,
        day_totals=MacroTotals(
            kcal=round(day_kcal, 1),
            protein_g=round(day_protein, 1),
            carb_g=round(day_carb, 1),
            fat_g=round(day_fat, 1),
        ),
        notes="Plan generated by deterministic fallback.",
    )


def _parse_claude_response(
    content: str,
    targets: MacroTargets,
    item_map: dict[str, MenuItem],
    meal_labels: list[str],
    target_date: str,
) -> MealPlan:
    data = json.loads(content)
    meals_data = data.get("meals", [])
    meals: list[MealSlot] = []

    for meal_data in meals_data:
        item_ids = meal_data.get("items", [])
        # Validate all IDs exist
        valid_ids = [iid for iid in item_ids if iid in item_map]
        if not valid_ids:
            raise ValueError(f"Meal {meal_data.get('label')} has no valid item IDs")

        # Recompute totals from real nutrition data (don't trust model arithmetic)
        real_kcal = sum(item_map[iid].nutrition.kcal for iid in valid_ids)
        real_protein = sum(item_map[iid].nutrition.protein_g for iid in valid_ids)
        real_carb = sum(item_map[iid].nutrition.carb_g for iid in valid_ids)
        real_fat = sum(item_map[iid].nutrition.fat_g for iid in valid_ids)

        first_loc = item_map[valid_ids[0]].location if valid_ids else "Unknown"

        meals.append(MealSlot(
            label=meal_data.get("label", "Meal"),
            location=meal_data.get("location", first_loc),
            items=valid_ids,
            totals=MacroTotals(
                kcal=round(real_kcal, 1),
                protein_g=round(real_protein, 1),
                carb_g=round(real_carb, 1),
                fat_g=round(real_fat, 1),
            ),
            rationale=meal_data.get("rationale", ""),
        ))

    day_kcal = sum(m.totals.kcal for m in meals)
    day_protein = sum(m.totals.protein_g for m in meals)
    day_carb = sum(m.totals.carb_g for m in meals)
    day_fat = sum(m.totals.fat_g for m in meals)

    return MealPlan(
        date=target_date,
        targets=targets,
        meals=meals,
        day_totals=MacroTotals(
            kcal=round(day_kcal, 1),
            protein_g=round(day_protein, 1),
            carb_g=round(day_carb, 1),
            fat_g=round(day_fat, 1),
        ),
        notes=data.get("notes", ""),
    )


async def generate_plan(
    profile: UserProfile,
    all_items: list[MenuItem],
    target_date: str,
) -> MealPlan:
    targets, warnings = compute_targets(profile)

    candidates = _filter_items(all_items, profile)
    if not candidates:
        candidates = all_items  # safety net

    meal_labels = MEAL_LABELS_BY_COUNT.get(profile.meals_per_day, ["Brunch", "Lunch", "Dinner"])
    item_map = {item.id: item for item in all_items}

    system_prompt = _load_system_prompt()
    user_prompt = _build_user_prompt(profile, targets, candidates, target_date, meal_labels)

    client = _get_client()

    last_error: Exception | None = None
    for attempt in range(2):
        try:
            response = await client.messages.create(
                model=MODEL,
                max_tokens=2048,
                timeout=30.0,
                system=system_prompt,
                messages=[{"role": "user", "content": user_prompt}],
            )
            raw = response.content[0].text.strip()
            # Strip markdown code fences if present
            if raw.startswith("```"):
                raw = raw.split("```")[1]
                if raw.startswith("json"):
                    raw = raw[4:]
            plan = _parse_claude_response(raw, targets, item_map, meal_labels, target_date)
            plan.date = target_date
            if warnings:
                plan.notes = (
                    " ".join(w.message for w in warnings) + " " + plan.notes
                ).strip()
            return plan
        except Exception as e:
            last_error = e
            continue

    # Deterministic fallback so the endpoint never 500s
    plan = _greedy_fallback(targets, candidates, meal_labels)
    plan.date = target_date
    plan.notes = f"[Fallback plan — Claude unavailable: {last_error}] " + plan.notes
    if warnings:
        plan.notes = " ".join(w.message for w in warnings) + " " + plan.notes
    return plan
