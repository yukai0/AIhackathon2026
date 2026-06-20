import Foundation

// MARK: - Shared value types

struct NutritionInfo: Codable, Equatable {
    var kcal: Double
    var proteinG: Double
    var carbG: Double
    var fatG: Double
    var fiberG: Double
    var sugarG: Double
    var sodiumMg: Double
    var satFatG: Double
    var transFatG: Double
    var cholesterolMg: Double
    var estimated: Bool
    var confidence: String

    enum CodingKeys: String, CodingKey {
        case kcal, estimated, confidence
        case proteinG = "protein_g"
        case carbG = "carb_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case sodiumMg = "sodium_mg"
        case satFatG = "sat_fat_g"
        case transFatG = "trans_fat_g"
        case cholesterolMg = "cholesterol_mg"
    }
}

struct MacroTotals: Codable, Equatable {
    var kcal: Double
    var proteinG: Double
    var carbG: Double
    var fatG: Double

    enum CodingKeys: String, CodingKey {
        case kcal
        case proteinG = "protein_g"
        case carbG = "carb_g"
        case fatG = "fat_g"
    }
}

// MARK: - MenuItem

struct MenuItem: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var station: String
    var location: String
    var mealPeriod: String
    var date: String
    var dietFlags: [String]
    var allergens: [String]
    var carbon: String?
    var carbonKgCo2: Double?
    var servingDesc: String
    var nutrition: NutritionInfo

    enum CodingKeys: String, CodingKey {
        case id, name, station, location, date, allergens, carbon, nutrition
        case mealPeriod = "meal_period"
        case dietFlags = "diet_flags"
        case carbonKgCo2 = "carbon_kg_co2"
        case servingDesc = "serving_desc"
    }
}

// MARK: - UserProfile

struct UserProfile: Codable, Equatable {
    var heightCm: Double = 170
    var weightKg: Double = 65
    var age: Int = 20
    var sex: String = "unspecified"
    var activityLevel: String = "moderate"
    var goalType: String = "maintain"
    var goalWeightKg: Double? = nil
    var mealsPerDay: Int = 3
    var dietRestrictions: [String] = []
    var excludeAllergens: [String] = []
    var preferredLocations: [String] = []

    enum CodingKeys: String, CodingKey {
        case age, sex, nutrition
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case activityLevel = "activity_level"
        case goalType = "goal_type"
        case goalWeightKg = "goal_weight_kg"
        case mealsPerDay = "meals_per_day"
        case dietRestrictions = "diet_restrictions"
        case excludeAllergens = "exclude_allergens"
        case preferredLocations = "preferred_locations"
    }
}

// MARK: - MealPlan

struct MealSlot: Codable, Identifiable {
    var id: String { label + location }
    var label: String
    var location: String
    var items: [String]
    var totals: MacroTotals
    var rationale: String
}

struct MealPlan: Codable, Identifiable {
    var id: String { date }
    var date: String
    var targets: MacroTotals
    var meals: [MealSlot]
    var dayTotals: MacroTotals
    var notes: String
    var disclaimer: String

    enum CodingKeys: String, CodingKey {
        case date, targets, meals, notes, disclaimer
        case dayTotals = "day_totals"
    }
}

// MARK: - PlanRequest

struct PlanRequest: Codable {
    var profile: UserProfile
    var date: String
}
