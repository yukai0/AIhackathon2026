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

extension MacroTotals {
    static let zero = MacroTotals(kcal: 0, proteinG: 0, carbG: 0, fatG: 0)

    mutating func add(_ nutrition: NutritionInfo) {
        kcal += nutrition.kcal
        proteinG += nutrition.proteinG
        carbG += nutrition.carbG
        fatG += nutrition.fatG
    }

    mutating func add(_ totals: MacroTotals) {
        kcal += totals.kcal
        proteinG += totals.proteinG
        carbG += totals.carbG
        fatG += totals.fatG
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

extension MenuItem {
    var diningHallPortionText: String {
        guard let ounces = servingOunces else {
            return servingDesc.isEmpty ? "Ask for one scoop" : servingDesc
        }

        let text = "\(name) \(station)".lowercased()

        if text.contains("bagel") || text.contains("roll") || text.contains("patty")
            || text.contains("breast") || text.contains("thigh") {
            let pieces = max(1, Int((ounces / 4).rounded()))
            return pieces == 1 ? "1 piece" : "\(pieces) pieces"
        }

        if text.contains("seed") || text.contains("almond") {
            return "1 topping spoon"
        }

        if text.contains("dressing") || text.contains("vinaigrette") || text.contains("sauce") {
            return "1 ladle"
        }

        if text.contains("stew") || text.contains("curry") || text.contains("soup") {
            let ladles = max(1, Int((ounces / 4).rounded()))
            return ladles == 1 ? "1 ladle" : "\(ladles) ladles"
        }

        let spoons = max(1, Int((ounces / 3).rounded()))
        return spoons == 1 ? "1 serving spoon" : "\(spoons) serving spoons"
    }

    private var servingOunces: Double? {
        let lowercasedServing = servingDesc.lowercased()
        guard lowercasedServing.contains("oz") else { return nil }

        return lowercasedServing
            .split(separator: " ")
            .compactMap { Double(String($0).replacingOccurrences(of: ",", with: "")) }
            .first
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
    var goalTimelineWeeks: Int? = nil
    var mealsPerDay: Int = 3
    var dietRestrictions: [String] = []
    var excludeAllergens: [String] = []
    var preferredLocations: [String] = ["Crossroads"]
    var dislikedFoods: [String] = []

    init(
        heightCm: Double = 170,
        weightKg: Double = 65,
        age: Int = 20,
        sex: String = "unspecified",
        activityLevel: String = "moderate",
        goalType: String = "maintain",
        goalWeightKg: Double? = nil,
        goalTimelineWeeks: Int? = nil,
        mealsPerDay: Int = 3,
        dietRestrictions: [String] = [],
        excludeAllergens: [String] = [],
        preferredLocations: [String] = ["Crossroads"],
        dislikedFoods: [String] = []
    ) {
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.age = age
        self.sex = sex
        self.activityLevel = activityLevel
        self.goalType = goalType
        self.goalWeightKg = goalWeightKg
        self.goalTimelineWeeks = goalTimelineWeeks
        self.mealsPerDay = mealsPerDay
        self.dietRestrictions = dietRestrictions
        self.excludeAllergens = excludeAllergens
        self.preferredLocations = preferredLocations
        self.dislikedFoods = dislikedFoods
    }

    enum CodingKeys: String, CodingKey {
        case age, sex
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case activityLevel = "activity_level"
        case goalType = "goal_type"
        case goalWeightKg = "goal_weight_kg"
        case goalTimelineWeeks = "goal_timeline_weeks"
        case mealsPerDay = "meals_per_day"
        case dietRestrictions = "diet_restrictions"
        case excludeAllergens = "exclude_allergens"
        case preferredLocations = "preferred_locations"
        case dislikedFoods = "disliked_foods"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        heightCm = try values.decodeIfPresent(Double.self, forKey: .heightCm) ?? 170
        weightKg = try values.decodeIfPresent(Double.self, forKey: .weightKg) ?? 65
        age = try values.decodeIfPresent(Int.self, forKey: .age) ?? 20
        sex = try values.decodeIfPresent(String.self, forKey: .sex) ?? "unspecified"
        activityLevel = try values.decodeIfPresent(String.self, forKey: .activityLevel) ?? "moderate"
        goalType = try values.decodeIfPresent(String.self, forKey: .goalType) ?? "maintain"
        goalWeightKg = try values.decodeIfPresent(Double.self, forKey: .goalWeightKg)
        goalTimelineWeeks = try values.decodeIfPresent(Int.self, forKey: .goalTimelineWeeks)
        mealsPerDay = try values.decodeIfPresent(Int.self, forKey: .mealsPerDay) ?? 3
        dietRestrictions = try values.decodeIfPresent([String].self, forKey: .dietRestrictions) ?? []
        excludeAllergens = try values.decodeIfPresent([String].self, forKey: .excludeAllergens) ?? []
        preferredLocations = try values.decodeIfPresent([String].self, forKey: .preferredLocations) ?? []
        dislikedFoods = try values.decodeIfPresent([String].self, forKey: .dislikedFoods) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(heightCm, forKey: .heightCm)
        try values.encode(weightKg, forKey: .weightKg)
        try values.encode(age, forKey: .age)
        try values.encode(sex, forKey: .sex)
        try values.encode(activityLevel, forKey: .activityLevel)
        try values.encode(goalType, forKey: .goalType)
        try values.encodeIfPresent(goalWeightKg, forKey: .goalWeightKg)
        try values.encodeIfPresent(goalTimelineWeeks, forKey: .goalTimelineWeeks)
        try values.encode(mealsPerDay, forKey: .mealsPerDay)
        try values.encode(dietRestrictions, forKey: .dietRestrictions)
        try values.encode(excludeAllergens, forKey: .excludeAllergens)
        try values.encode(preferredLocations, forKey: .preferredLocations)
        try values.encode(dislikedFoods, forKey: .dislikedFoods)
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
    var warnings: [String]?
    var disclaimer: String

    enum CodingKeys: String, CodingKey {
        case date, targets, meals, notes, warnings, disclaimer
        case dayTotals = "day_totals"
    }
}

// MARK: - PlanRequest

struct PlanRequest: Codable {
    var profile: UserProfile
    var date: String
}

// MARK: - Demo fallback data

enum DemoData {
    static let menuItems: [MenuItem] = [
        item(
            id: "4a64758fea5b3f7d",
            name: "Plain Bagels",
            station: "Bagel Station",
            mealPeriod: "Brunch",
            servingDesc: "3.35 oz",
            dietFlags: ["vegan"],
            allergens: ["wheat", "soy", "gluten"],
            carbon: "medium",
            carbonKgCo2: 0.14,
            nutrition: nutrition(260.09, 8.99, 50.98, 2.0, 2.0, 6.0, 499.85, 0.5, 0.0, 0.0)
        ),
        item(
            id: "cb2c3759ec550fc2",
            name: "Scrambled Eggs",
            station: "Breakfast Entree",
            mealPeriod: "Brunch",
            servingDesc: "3.93 oz",
            dietFlags: ["vegetarian"],
            allergens: ["egg"],
            carbon: "high",
            carbonKgCo2: 0.4,
            nutrition: nutrition(184.98, 13.92, 2.32, 12.88, 0.0, 0.0, 167.04, 3.75, 0.0, 405.61)
        ),
        item(
            id: "a40dd0e37ff2f854",
            name: "Spinach Tofu Tomato Scramble",
            station: "Plant Forward Breakfast",
            mealPeriod: "Brunch",
            servingDesc: "3.81 oz",
            dietFlags: ["vegan"],
            allergens: ["soy"],
            carbon: "low",
            carbonKgCo2: 0.03,
            nutrition: nutrition(124.27, 12.64, 6.35, 5.55, 2.31, 0.41, 140.29, 0.21, 0.0, 0.0)
        ),
        item(
            id: "94ca33d0030c62da",
            name: "Mung Bean Patty",
            station: "Plant Forward Breakfast",
            mealPeriod: "Brunch",
            servingDesc: "3.4 oz",
            dietFlags: ["vegan"],
            allergens: [],
            carbon: "high",
            carbonKgCo2: 0.24,
            nutrition: nutrition(169.21, 11.84, 1.69, 11.84, 0.0, 0.0, 439.67, 0.85, 0.0, 0.0)
        ),
        item(
            id: "c4f1fd2dea87cca2",
            name: "Non Fat Plain Greek Yogurt",
            station: "Yogurt Bar",
            mealPeriod: "Brunch",
            servingDesc: "6 oz",
            dietFlags: ["vegetarian"],
            allergens: ["milk"],
            carbon: "high",
            carbonKgCo2: 0.49,
            nutrition: nutrition(100.0, 17.33, 6.12, 0.66, 0.0, 5.51, 61.23, 0.2, 0.02, 8.5)
        ),
        item(
            id: "7ea61fe6b78c6db9",
            name: "Sliced Almond",
            station: "Yogurt Bar",
            mealPeriod: "Brunch",
            servingDesc: "0.5 oz",
            dietFlags: ["vegan"],
            allergens: ["treenut"],
            carbon: "low",
            carbonKgCo2: 0.06,
            nutrition: nutrition(81.05, 3.04, 3.04, 7.09, 2.03, 0.47, 0.0, 0.51, 0.0, 0.0)
        ),
        item(
            id: "46b0391ba459b937",
            name: "Hawaiian Dinner Roll",
            station: "Pasta",
            mealPeriod: "Lunch",
            servingDesc: "1 oz",
            dietFlags: ["vegetarian"],
            allergens: ["milk", "egg", "wheat", "soy", "gluten"],
            carbon: "low",
            carbonKgCo2: 0.04,
            nutrition: nutrition(91.18, 3.04, 15.19, 2.02, 0.51, 5.06, 75.94, 1.01, 0.0, 15.19)
        ),
        item(
            id: "e745a045386e8997",
            name: "Halal Rosemary Chicken",
            station: "Allergen Friendly - Lunch",
            mealPeriod: "Lunch",
            servingDesc: "3.94 oz",
            dietFlags: ["halal"],
            allergens: [],
            carbon: "low",
            carbonKgCo2: 0.06,
            nutrition: nutrition(153.21, 20.85, 0.06, 7.06, 0.04, 0.0, 300.97, 1.43, 0.02, 99.03)
        ),
        item(
            id: "1b89dee893bbd946",
            name: "Yemeni Beef Stew",
            station: "Entree",
            mealPeriod: "Lunch",
            servingDesc: "4.5 oz",
            dietFlags: [],
            allergens: [],
            carbon: "high",
            carbonKgCo2: 4.29,
            nutrition: nutrition(176.13, 22.9, 2.47, 8.32, 0.46, 0.56, 278.54, 2.35, 0.24, 66.11)
        ),
        item(
            id: "bfe0f8f0f3b4ffc7",
            name: "Vegetable Yemeni Zurbian Basmati Rice",
            station: "Entree",
            mealPeriod: "Lunch",
            servingDesc: "3.67 oz",
            dietFlags: ["vegan"],
            allergens: [],
            carbon: "medium",
            carbonKgCo2: 0.1,
            nutrition: nutrition(115.29, 2.25, 24.29, 1.3, 0.97, 0.79, 199.38, 0.16, 0.0, 0.0)
        ),
        item(
            id: "05e7c7449a9c08b7",
            name: "Base - Mixed Greens",
            station: "Salad Bar",
            mealPeriod: "Lunch",
            servingDesc: "4 oz",
            dietFlags: ["vegan"],
            allergens: [],
            carbon: "low",
            carbonKgCo2: 0.06,
            nutrition: nutrition(26.29, 3.24, 4.12, 0.44, 2.49, 0.48, 89.58, 0.07, 0.0, 0.0)
        ),
        item(
            id: "8e26a4ae4b074db1",
            name: "Pumpkin Seeds",
            station: "Salad Bar",
            mealPeriod: "Lunch",
            servingDesc: "1 oz",
            dietFlags: ["vegan"],
            allergens: [],
            carbon: "medium",
            carbonKgCo2: 0.12,
            nutrition: nutrition(158.48, 8.57, 3.04, 13.91, 1.7, 0.4, 1.98, 2.46, 0.02, 0.0)
        ),
        item(
            id: "fbdd2ab7ee85c44b",
            name: "Balsamic Vinaigrette",
            station: "Salad Bar",
            mealPeriod: "Lunch",
            servingDesc: "1 oz",
            dietFlags: ["vegan"],
            allergens: [],
            carbon: "low",
            carbonKgCo2: 0.05,
            nutrition: nutrition(54.91, 0.0, 4.57, 4.57, 0.0, 3.66, 182.9, 0.46, 0.0, 0.0)
        ),
        item(
            id: "5192d55749e39718",
            name: "Penne Pasta",
            station: "Pasta",
            mealPeriod: "Dinner",
            servingDesc: "4.03 oz",
            dietFlags: ["vegan"],
            allergens: ["wheat", "gluten"],
            carbon: "low",
            carbonKgCo2: 0.08,
            nutrition: nutrition(168.95, 5.58, 33.43, 1.86, 1.59, 1.62, 393.13, 0.15, 0.0, 0.0)
        ),
        item(
            id: "451d96b6a96e9a4c",
            name: "Braised Bok Choy",
            station: "Plant Forward",
            mealPeriod: "Dinner",
            servingDesc: "5.09 oz",
            dietFlags: ["vegan"],
            allergens: [],
            carbon: "medium",
            carbonKgCo2: 0.1,
            nutrition: nutrition(42.05, 2.12, 4.14, 2.47, 1.49, 1.95, 481.09, 0.2, 0.0, 0.0)
        ),
        item(
            id: "48a630b402b09848",
            name: "Halal Rosemary Roasted Chicken Thigh",
            station: "Allergen Friendly - Dinner",
            mealPeriod: "Dinner",
            servingDesc: "4.04 oz",
            dietFlags: ["halal"],
            allergens: [],
            carbon: "high",
            carbonKgCo2: 0.48,
            nutrition: nutrition(153.99, 21.44, 0.24, 6.79, 0.06, 0.06, 398.75, 1.47, 0.02, 102.44)
        ),
        item(
            id: "860cf5b3456fbdc6",
            name: "Quinoa",
            station: "Allergen Friendly - Dinner",
            mealPeriod: "Dinner",
            servingDesc: "5.58 oz",
            dietFlags: ["vegan"],
            allergens: [],
            carbon: "medium",
            carbonKgCo2: 0.09,
            nutrition: nutrition(200.71, 6.06, 29.27, 5.74, 3.04, 0.4, 98.6, 0.46, 0.0, 0.0)
        ),
        item(
            id: "3a7060223884008e",
            name: "Halal Coconut Curry Chicken Breast",
            station: "Entree",
            mealPeriod: "Dinner",
            servingDesc: "6.56 oz",
            dietFlags: ["halal"],
            allergens: [],
            carbon: "medium",
            carbonKgCo2: 0.11,
            nutrition: nutrition(268.68, 19.68, 6.86, 17.61, 2.03, 1.6, 433.56, 7.09, 0.09, 58.02)
        )
    ]

    static let menuItemsByID: [String: MenuItem] = Dictionary(
        menuItems.map { ($0.id, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    private static func item(
        id: String,
        name: String,
        station: String,
        mealPeriod: String,
        servingDesc: String,
        dietFlags: [String],
        allergens: [String],
        carbon: String?,
        carbonKgCo2: Double?,
        nutrition: NutritionInfo
    ) -> MenuItem {
        MenuItem(
            id: id,
            name: name,
            station: station,
            location: "Crossroads",
            mealPeriod: mealPeriod,
            date: "2026-06-20",
            dietFlags: dietFlags,
            allergens: allergens,
            carbon: carbon,
            carbonKgCo2: carbonKgCo2,
            servingDesc: servingDesc,
            nutrition: nutrition
        )
    }

    private static func nutrition(
        _ kcal: Double,
        _ proteinG: Double,
        _ carbG: Double,
        _ fatG: Double,
        _ fiberG: Double,
        _ sugarG: Double,
        _ sodiumMg: Double,
        _ satFatG: Double,
        _ transFatG: Double,
        _ cholesterolMg: Double
    ) -> NutritionInfo {
        NutritionInfo(
            kcal: kcal,
            proteinG: proteinG,
            carbG: carbG,
            fatG: fatG,
            fiberG: fiberG,
            sugarG: sugarG,
            sodiumMg: sodiumMg,
            satFatG: satFatG,
            transFatG: transFatG,
            cholesterolMg: cholesterolMg,
            estimated: false,
            confidence: "high"
        )
    }
}
