import Foundation

enum Config {
    // Point at localhost for Simulator, swap to deployed URL for device
    static let baseURL = URL(string: "http://localhost:8000")!
    static let apiTimeout: TimeInterval = 60
}

extension Notification.Name {
    static let bearfuelRegeneratePlan = Notification.Name("bearfuel.regeneratePlan")
}
