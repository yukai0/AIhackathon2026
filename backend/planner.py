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
KCAL_PER_KG = 7700.0
MAX_WEEKLY_LOSS_KG = 0.75
MAX_WEEKLY_GAIN_KG = 0.35
MAX_AI_CANDIDATES = 64

MEAL_LABELS_BY_COUNT = {
    1: ["Dinner"],
    2: ["Brunch", "Dinner"],
    3: ["Brunch", "Lunch", "Dinner"],
    4: ["Brunch", "Lunch", "Dinner", "Late Snack"],
}

CATEGORY_KEYWORDS: list[tuple[str, tuple[str, ...]]] = [
    ("protein", ("chicken", "beef", "pork", "turkey", "fish", "salmon", "egg", "tofu", "bean", "lentil", "yogurt")),
    ("grain", ("rice", "quinoa", "pasta", "noodle", "bagel", "bread", "roll", "tortilla", "oat")),
    ("vegetable", ("salad", "greens", "bok choy", "broccoli", "spinach", "vegetable", "carrot", "pepper")),
    ("sauce", ("dressing", "vinaigrette", "sauce", "salsa", "gravy")),
    ("dessert", ("cake", "cookie", "brownie", "pie", "dessert", "pudding")),
    ("topping", ("seed", "almond", "nut", "granola")),
]

VISUAL_SYMBOL_BY_CATEGORY = {
    "protein": "fork.knife",
    "grain": "takeoutbag.and.cup.and.straw.fill",
    "vegetable": "leaf.fill",
    "sauce": "drop.fill",
    "dessert": "birthday.cake.fill",
    "topping": "circle.hexagongrid.fill",
    "other": "fork.knife.circle.fill",
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

    if profile.goal_weight_kg is not None and profile.goal_timeline_weeks:
        delta_kg = profile.goal_weight_kg - profile.weight_kg
        weekly_delta = delta_kg / profile.goal_timeline_weeks

        if profile.goal_type == "cut" and delta_kg > 0.25:
            warnings.append(HealthWarning(
                code="goal_direction_conflict",
                message="Your goal weight is above your current weight, so the timeline does not match a cut goal.",
                severity="warning",
            ))
        elif profile.goal_type == "lean_gain" and delta_kg < -0.25:
            warnings.append(HealthWarning(
                code="goal_direction_conflict",
                message="Your goal weight is below your current weight, so the timeline does not match a lean gain goal.",
                severity="warning",
            ))

        if weekly_delta < -MAX_WEEKLY_LOSS_KG:
            warnings.append(HealthWarning(
                code="goal_timeline_too_aggressive",
                message=(
                    f"Your requested timeline implies losing about {abs(weekly_delta):.1f} kg/week. "
                    f"The plan is capped near {MAX_WEEKLY_LOSS_KG:.2f} kg/week for safety."
                ),
                severity="warning",
            ))
        elif weekly_delta > MAX_WEEKLY_GAIN_KG:
            warnings.append(HealthWarning(
                code="goal_timeline_too_aggressive",
                message=(
                    f"Your requested timeline implies gaining about {weekly_delta:.1f} kg/week. "
                    f"The plan is capped near {MAX_WEEKLY_GAIN_KG:.2f} kg/week for a more sustainable pace."
                ),
                severity="warning",
            ))

        daily_kcal_adjustment = delta_kg * KCAL_PER_KG / (profile.goal_timeline_weeks * 7)
        adj = daily_kcal_adjustment / max(tdee, 1)

    # Clamp adjustments to safety bounds
    if adj < -MAX_DEFICIT_PCT:
        warnings.append(HealthWarning(
            code="deficit_clamped",
            message="The requested deficit was above the app's safety limit, so calories were raised.",
            severity="warning",
        ))
        adj = -MAX_DEFICIT_PCT
    if adj > MAX_SURPLUS_PCT:
        warnings.append(HealthWarning(
            code="surplus_clamped",
            message="The requested surplus was above the app's safety limit, so calories were lowered.",
            severity="warning",
        ))
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

    if profile.diet_restrictions:
        filtered = [i for i in filtered if _matches_diet_restrictions(i, profile.diet_restrictions)]

    if profile.exclude_allergens:
        excluded = set(profile.exclude_allergens)
        filtered = [i for i in filtered if not excluded.intersection(set(i.allergens))]

    disliked_terms = [term.strip().lower() for term in profile.disliked_foods if term.strip()]
    if disliked_terms:
        filtered = [
            i for i in filtered
            if not any(term in f"{i.name} {i.station}".lower() for term in disliked_terms)
        ]

    return filtered


def _matches_diet_restrictions(item: MenuItem, restrictions: list[str]) -> bool:
    flags = set(item.diet_flags)
    for restriction in restrictions:
        if restriction == "vegetarian":
            if not {"vegetarian", "vegan"}.intersection(flags):
                return False
        elif restriction not in flags:
            return False
    return True


def _availability_warnings(
    candidates: list[MenuItem],
    targets: MacroTargets,
    meal_labels: list[str],
    profile: UserProfile,
) -> list[HealthWarning]:
    warnings: list[HealthWarning] = []

    if not candidates:
        warnings.append(HealthWarning(
            code="no_matching_foods",
            message="No dining hall foods matched all selected diet, allergen, location, and dislike filters.",
            severity="error",
        ))
        return warnings

    minimum_variety = max(6, len(meal_labels) * 3)
    if len(candidates) < minimum_variety:
        warnings.append(HealthWarning(
            code="limited_food_variety",
            message=(
                f"Only {len(candidates)} foods match your filters today. "
                "The plan may not have enough variety to reliably hit every target."
            ),
            severity="warning",
        ))

    max_items = max(1, len(meal_labels) * 4)
    top_kcal = sorted(candidates, key=lambda item: item.nutrition.kcal, reverse=True)[:max_items]
    top_protein = sorted(candidates, key=lambda item: item.nutrition.protein_g, reverse=True)[:max_items]
    possible_kcal = sum(item.nutrition.kcal for item in top_kcal)
    possible_protein = sum(item.nutrition.protein_g for item in top_protein)

    if possible_kcal < targets.kcal * 0.85:
        warnings.append(HealthWarning(
            code="calorie_target_unlikely",
            message=(
                "With the current filters, the available single-serving foods may not reach "
                "your daily calorie target without extra portions or relaxing a filter."
            ),
            severity="warning",
        ))

    if possible_protein < targets.protein_g * 0.85:
        warnings.append(HealthWarning(
            code="protein_target_unlikely",
            message=(
                "With the current filters, there may not be enough protein-dense options today "
                "to meet your protein target."
            ),
            severity="warning",
        ))

    if profile.diet_restrictions:
        matched_flags = {flag for item in candidates for flag in item.diet_flags}
        missing_flags = [flag for flag in profile.diet_restrictions if flag not in matched_flags]
        if missing_flags:
            warnings.append(HealthWarning(
                code="diet_filter_sparse",
                message=f"Today's menu has very limited options matching: {', '.join(missing_flags)}.",
                severity="warning",
            ))

    return warnings


def _food_category(item: MenuItem) -> str:
    text = f"{item.name} {item.station}".lower()
    for category, keywords in CATEGORY_KEYWORDS:
        if any(keyword in text for keyword in keywords):
            return category
    return "other"


def _serving_ounces(serving_desc: str) -> float | None:
    text = serving_desc.lower()
    if "oz" not in text:
        return None
    for token in text.replace(",", "").split():
        try:
            return float(token)
        except ValueError:
            continue
    return None


def _portion_hint(item: MenuItem) -> str:
    ounces = _serving_ounces(item.serving_desc)
    if ounces is None:
        return "1 dining-hall serving"

    category = _food_category(item)
    text = f"{item.name} {item.station}".lower()
    if "bagel" in text or "roll" in text or "patty" in text or "breast" in text or "thigh" in text:
        pieces = max(1, round(ounces / 4))
        return f"{pieces} piece" if pieces == 1 else f"{pieces} pieces"
    if category == "topping":
        return "1 topping spoon"
    if category == "sauce":
        return "1 ladle"
    if "stew" in text or "curry" in text or "soup" in text:
        ladles = max(1, round(ounces / 4))
        return f"{ladles} ladle" if ladles == 1 else f"{ladles} ladles"

    spoons = max(1, round(ounces / 3))
    return f"{spoons} serving spoon" if spoons == 1 else f"{spoons} serving spoons"


def _risk_codes(item: MenuItem) -> list[str]:
    risks: list[str] = []
    if item.nutrition.sodium_mg >= 900:
        risks.append("high_sodium")
    if item.nutrition.sat_fat_g >= 8:
        risks.append("high_sat_fat")
    if item.nutrition.sugar_g >= 25:
        risks.append("high_sugar")
    if item.nutrition.cholesterol_mg >= 250:
        risks.append("high_cholesterol")
    return risks


def _period_matches(item: MenuItem, meal_label: str) -> bool:
    if item.meal_period == "All Day":
        return True
    if meal_label == "Late Snack":
        return item.meal_period in ("Dinner", "All Day")
    return item.meal_period == meal_label


def _item_score(item: MenuItem, targets: MacroTargets) -> float:
    kcal = max(item.nutrition.kcal, 1)
    protein_density = item.nutrition.protein_g / kcal
    protein_score = min(item.nutrition.protein_g / max(targets.protein_g / 3, 1), 1.4)
    calorie_score = min(item.nutrition.kcal / max(targets.kcal / 9, 1), 1.2)
    fiber_score = min(item.nutrition.fiber_g / 8, 0.5)
    category_bonus = {
        "protein": 0.45,
        "vegetable": 0.25,
        "grain": 0.18,
        "topping": 0.08,
        "sauce": -0.08,
        "dessert": -0.22,
    }.get(_food_category(item), 0)
    risk_penalty = 0.18 * len(_risk_codes(item))
    return protein_density * 20 + protein_score + calorie_score + fiber_score + category_bonus - risk_penalty


def _shortlist_candidates(
    candidates: list[MenuItem],
    targets: MacroTargets,
    meal_labels: list[str],
) -> list[MenuItem]:
    selected: dict[str, MenuItem] = {}

    for label in meal_labels:
        meal_items = [item for item in candidates if _period_matches(item, label)]
        if not meal_items:
            meal_items = candidates

        for item in sorted(meal_items, key=lambda i: _item_score(i, targets), reverse=True)[:18]:
            selected[item.id] = item

        for category in ("protein", "grain", "vegetable", "topping"):
            category_items = [item for item in meal_items if _food_category(item) == category]
            for item in sorted(category_items, key=lambda i: _item_score(i, targets), reverse=True)[:5]:
                selected[item.id] = item

    for item in sorted(candidates, key=lambda i: i.nutrition.protein_g, reverse=True)[:16]:
        selected[item.id] = item
    for item in sorted(candidates, key=lambda i: i.nutrition.kcal, reverse=True)[:10]:
        selected[item.id] = item

    ranked = sorted(selected.values(), key=lambda i: _item_score(i, targets), reverse=True)
    return ranked[:MAX_AI_CANDIDATES]


def _compact_item_payload(item: MenuItem) -> dict:
    category = _food_category(item)
    payload = {
        "id": item.id,
        "n": item.name,
        "st": item.station,
        "loc": item.location,
        "mp": item.meal_period,
        "cat": category,
        "icon": VISUAL_SYMBOL_BY_CATEGORY.get(category, VISUAL_SYMBOL_BY_CATEGORY["other"]),
        "portion": _portion_hint(item),
        "k": round(item.nutrition.kcal),
        "p": round(item.nutrition.protein_g, 1),
        "c": round(item.nutrition.carb_g, 1),
        "f": round(item.nutrition.fat_g, 1),
    }
    if item.diet_flags:
        payload["flags"] = item.diet_flags
    risks = _risk_codes(item)
    if risks:
        payload["risk"] = risks
    return payload


def _seed_plan_payload(plan: MealPlan) -> list[dict]:
    return [
        {
            "label": meal.label,
            "loc": meal.location,
            "items": meal.items,
            "k": round(meal.totals.kcal),
            "p": round(meal.totals.protein_g, 1),
            "c": round(meal.totals.carb_g, 1),
            "f": round(meal.totals.fat_g, 1),
        }
        for meal in plan.meals
    ]


def _plan_is_good_enough(plan: MealPlan, targets: MacroTargets) -> bool:
    if not plan.meals or any(not meal.items for meal in plan.meals):
        return False

    checks = [
        (plan.day_totals.kcal, targets.kcal, 0.82, 1.12),
        (plan.day_totals.protein_g, targets.protein_g, 0.85, 1.25),
        (plan.day_totals.carb_g, targets.carb_g, 0.55, 1.35),
        (plan.day_totals.fat_g, targets.fat_g, 0.55, 1.35),
    ]
    return all(target <= 0 or lower <= value / target <= upper for value, target, lower, upper in checks)


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
    seed_plan: MealPlan,
    original_candidate_count: int,
) -> str:
    items_payload = [_compact_item_payload(item) for item in candidates]
    seed_payload = _seed_plan_payload(seed_plan)
    compact_items = json.dumps(items_payload, separators=(",", ":"))
    compact_seed = json.dumps(seed_payload, separators=(",", ":"))

    return f"""
Date: {target_date}
Student goal: {profile.goal_type}
Goal weight: {profile.goal_weight_kg if profile.goal_weight_kg is not None else 'none'}
Goal timeline weeks: {profile.goal_timeline_weeks or 'none'}
Daily targets: {targets.kcal:.0f} kcal | {targets.protein_g:.0f}g protein | {targets.carb_g:.0f}g carbs | {targets.fat_g:.0f}g fat
Meals needed: {meal_labels}
Diet restrictions: {profile.diet_restrictions or 'none'}
Allergens to avoid: {profile.exclude_allergens or 'none'}
Disliked foods to avoid: {profile.disliked_foods or 'none'}
Preferred locations: {profile.preferred_locations or 'any'}

The server already filtered {original_candidate_count} safe dining-hall dishes and shortlisted the best {len(candidates)} options.
Compact dish keys: id, n=name, st=station, loc=location, mp=meal period, cat=category, icon=precomputed app graphic, portion=dining-hall portion, k=kcal, p=protein, c=carbs, f=fat, risk=nutrition caution.
Shortlisted dishes:
{compact_items}

Local seed plan to refine:
{compact_seed}

Select dishes for each meal from the list above. Requirements:
1. Only use dish IDs from the provided list — do not invent items.
2. Do not select foods that conflict with diet restrictions, allergen exclusions, or disliked foods.
3. Prefer the seed plan unless a small substitution improves macro fit or safety.
4. Day totals should land within ±10% of each macro target and should not intentionally exceed targets.
5. Spread protein roughly evenly across meals.
6. For each meal, pick 1–4 complementary dishes from the same location if possible.
7. Use ordinary dining-hall single portions; do not imply supplement, medication, extreme restriction, or binge-style intake.
8. Avoid stacking risk-tagged items when safer alternatives are available.
9. Add a one-sentence rationale for each meal.

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
    target_date: str,
    warnings: list[HealthWarning],
) -> MealPlan:
    """Deterministic greedy selector — used when Claude fails twice."""
    # Sort by protein density to prioritize protein-dense items
    sorted_items = sorted(
        candidates, key=lambda x: x.nutrition.protein_g / max(x.nutrition.kcal, 1), reverse=True
    )

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
        period_items = [x for x in sorted_items if _period_matches(x, label)]
        if not period_items:
            period_items = sorted_items
        loc_items = [x for x in period_items if x.location == loc and x.id not in used_ids]
        if not loc_items:
            loc_items = [x for x in period_items if x.id not in used_ids]

        meal_items: list[MenuItem] = []
        meal_kcal = 0.0
        meal_protein = 0.0
        meal_carb = 0.0
        meal_fat = 0.0
        used_categories: set[str] = set()

        for _ in range(5):
            available = [item for item in loc_items if item.id not in used_ids and item.id not in {m.id for m in meal_items}]
            if not available:
                break

            def add_score(item: MenuItem) -> float:
                next_kcal = meal_kcal + item.nutrition.kcal
                next_protein = meal_protein + item.nutrition.protein_g
                kcal_distance = abs(per_meal_kcal - next_kcal) / max(per_meal_kcal, 1)
                protein_distance = abs(per_meal_protein - next_protein) / max(per_meal_protein, 1)
                overage_penalty = max(0, next_kcal - per_meal_kcal * 1.18) / max(per_meal_kcal, 1)
                category = _food_category(item)
                variety_bonus = -0.12 if category not in used_categories else 0.08
                risk_penalty = 0.08 * len(_risk_codes(item))
                return kcal_distance + protein_distance * 0.8 + overage_penalty + variety_bonus + risk_penalty

            item = min(available, key=add_score)
            next_kcal = meal_kcal + item.nutrition.kcal
            if meal_items and next_kcal > per_meal_kcal * 1.28:
                break
            meal_items.append(item)
            meal_kcal += item.nutrition.kcal
            meal_protein += item.nutrition.protein_g
            meal_carb += item.nutrition.carb_g
            meal_fat += item.nutrition.fat_g
            used_ids.add(item.id)
            used_categories.add(_food_category(item))
            if meal_kcal >= per_meal_kcal * 0.82 and meal_protein >= per_meal_protein * 0.75:
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
        date=target_date,
        targets=targets,
        meals=meals,
        day_totals=MacroTotals(
            kcal=round(day_kcal, 1),
            protein_g=round(day_protein, 1),
            carb_g=round(day_carb, 1),
            fat_g=round(day_fat, 1),
        ),
        notes="Plan generated by deterministic fallback.",
        warnings=[warning.message for warning in warnings],
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
    meal_labels = MEAL_LABELS_BY_COUNT.get(profile.meals_per_day, ["Brunch", "Lunch", "Dinner"])
    warnings.extend(_availability_warnings(candidates, targets, meal_labels, profile))
    warning_messages = [warning.message for warning in warnings]

    if not candidates:
        return MealPlan(
            date=target_date,
            targets=targets,
            meals=[],
            day_totals=MacroTotals(kcal=0, protein_g=0, carb_g=0, fat_g=0),
            notes="No safe plan could be generated with the current filters.",
            warnings=warning_messages,
        )

    shortlisted_candidates = _shortlist_candidates(candidates, targets, meal_labels)
    seed_plan = _greedy_fallback(targets, shortlisted_candidates, meal_labels, target_date, warnings)
    if _plan_is_good_enough(seed_plan, targets):
        seed_plan.notes = (
            "Plan generated from a precomputed dining-hall shortlist to reduce AI usage. "
            + seed_plan.notes
        )
        return seed_plan

    item_map = {item.id: item for item in shortlisted_candidates}

    system_prompt = _load_system_prompt()
    user_prompt = _build_user_prompt(
        profile,
        targets,
        shortlisted_candidates,
        target_date,
        meal_labels,
        seed_plan,
        len(candidates),
    )

    client = _get_client()

    last_error: Exception | None = None
    for attempt in range(2):
        try:
            response = await client.messages.create(
                model=MODEL,
                max_tokens=1200,
                timeout=25.0,
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
            plan.warnings = warning_messages
            return plan
        except Exception as e:
            last_error = e
            continue

    # Deterministic fallback so the endpoint never 500s
    plan = _greedy_fallback(targets, shortlisted_candidates, meal_labels, target_date, warnings)
    plan.notes = f"[Fallback plan from precomputed shortlist — Claude unavailable: {last_error}] " + plan.notes
    return plan
