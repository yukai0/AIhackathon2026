import Foundation

@MainActor
final class MenuViewModel: ObservableObject {
    @Published var items: [MenuItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isShowingFallback = false
    @Published var selectedLocation: String = "All"
    @Published var searchText: String = ""

    private let api = APIClient.shared

    var locations: [String] {
        ["All"] + Array(Set(items.map { $0.location })).sorted()
    }

    var filteredItems: [MenuItem] {
        var result = items
        if selectedLocation != "All" {
            result = result.filter { $0.location == selectedLocation }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.station.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var groupedItems: [(String, [MenuItem])] {
        let grouped = Dictionary(grouping: filteredItems) { $0.station }
        return grouped.sorted { $0.key < $1.key }
    }

    func load() async {
        guard items.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            items = try await api.fetchMenu()
            isShowingFallback = false
        } catch {
            items = DemoData.menuItems
            isShowingFallback = true
            errorMessage = nil
        }
        isLoading = false
    }
}
