from __future__ import annotations
from typing import Literal, Optional
from pydantic import BaseModel, Field


class NutritionInfo(BaseModel):
    kcal: float
    protein_g: float
    carb_g: float
    fat_g: float
    fiber_g: float = 0.0
    sugar_g: float = 0.0
    sodium_mg: float = 0.0
    sat_fat_g: float = 0.0
    trans_fat_g: float = 0.0
    cholesterol_mg: float = 0.0
    estimated: bool = False
    confidence: Literal["high", "medium", "low"] = "high"


DietFlag = Literal["vegan", "vegetarian", "halal", "kosher"]
AllergenFlag = Literal[
    "milk", "egg", "fish", "shellfish", "treenut",
    "wheat", "peanut", "soy", "sesame", "gluten", "pork", "alcohol"
]
CarbonRating = Literal["low", "medium", "high"]
MealPeriod = Literal["Brunch", "Lunch", "Dinner", "All Day"]
ActivityLevel = Literal["sedentary", "light", "moderate", "active", "very_active"]
GoalType = Literal["cut", "maintain", "lean_gain", "recomp", "athletic_performance"]
Sex = Literal["male", "female", "unspecified"]


class MenuItem(BaseModel):
    id: str
    name: str
    station: str
    location: str
    meal_period: MealPeriod
    date: str
    diet_flags: list[DietFlag] = Field(default_factory=list)
    allergens: list[AllergenFlag] = Field(default_factory=list)
    carbon: Optional[CarbonRating] = None
    carbon_kg_co2: Optional[float] = None
    serving_desc: str = ""
    nutrition: NutritionInfo


class UserProfile(BaseModel):
    height_cm: float = Field(ge=100, le=250)
    weight_kg: float = Field(ge=30, le=300)
    age: int = Field(ge=13, le=100)
    sex: Sex = "unspecified"
    activity_level: ActivityLevel = "moderate"
    goal_type: GoalType = "maintain"
    goal_weight_kg: Optional[float] = None
    meals_per_day: int = Field(default=3, ge=1, le=6)
    diet_restrictions: list[DietFlag] = Field(default_factory=list)
    exclude_allergens: list[AllergenFlag] = Field(default_factory=list)
    preferred_locations: list[str] = Field(default_factory=list)


class MacroTotals(BaseModel):
    kcal: float
    protein_g: float
    carb_g: float
    fat_g: float


class MacroTargets(MacroTotals):
    pass


class MealSlot(BaseModel):
    label: str
    location: str
    items: list[str]  # MenuItem ids
    totals: MacroTotals
    rationale: str


class MealPlan(BaseModel):
    date: str
    targets: MacroTargets
    meals: list[MealSlot]
    day_totals: MacroTotals
    notes: str = ""
    disclaimer: str = (
        "Nutrition from UC Berkeley dining data; may vary. Not medical advice."
    )


class PlanRequest(BaseModel):
    profile: UserProfile
    date: str = ""
    meal_periods: list[MealPeriod] = Field(default_factory=list)


class HealthWarning(BaseModel):
    code: str
    message: str
    severity: Literal["info", "warning", "error"]
