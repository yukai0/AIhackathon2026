import SwiftUI

struct MenuBrowserView: View {
    @StateObject private var vm = MenuViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.items.isEmpty {
                    ProgressView("Loading today's menu…")
                        .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(vm.groupedItems, id: \.0) { station, items in
                            Section(station) {
                                ForEach(items) { item in
                                    NavigationLink(destination: DishDetailView(item: item)) {
                                        MenuItemRow(item: item)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await vm.refresh() }
                }
            }
            .navigationTitle("Today's Menu")
            .searchable(text: $vm.searchText, prompt: "Search dishes…")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Location", selection: $vm.selectedLocation) {
                        ForEach(vm.locations, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .task { await vm.load() }
        }
    }
}

// MARK: - MenuItemRow

struct MenuItemRow: View {
    let item: MenuItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                carbonDot
            }
            HStack(spacing: 6) {
                ForEach(item.dietFlags, id: \.self) { flag in
                    DietBadge(flag: flag)
                }
                Spacer()
                Text("\(Int(item.nutrition.kcal)) kcal · \(Int(item.nutrition.proteinG))g P")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var carbonDot: some View {
        if let carbon = item.carbon {
            let color: Color = carbon == "low" ? .green : carbon == "medium" ? .yellow : .red
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .help("Carbon footprint: \(carbon)")
        }
    }
}
