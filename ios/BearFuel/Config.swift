import Foundation

enum Config {
    // Point at localhost for Simulator, swap to deployed URL for device
    static let baseURL = URL(string: "http://localhost:8002")!
    static let apiTimeout: TimeInterval = 30
}
