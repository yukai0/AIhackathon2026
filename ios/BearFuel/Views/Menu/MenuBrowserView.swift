import SwiftUI

struct MenuBrowserView: View {
    @StateObject private var vm = MenuViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.items.isEmpty {
                    ProgressView("Loading today's menu…")
                        .frame(maxHeight: .infinity)
                } else if vm.groupedItems.isEmpty {
                    ContentUnavailableView(
                        "No Dishes Found",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search or location.")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8, pinnedViews: []) {
                            ForEach(vm.groupedItems, id: \.0) { station, items in
                                // Section header
                                HStack {
                                    Text(station)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.berkeleyBlue)
                                    Spacer()
                                    Text("\(items.count) dishes")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 4)
                                .padding(.top, 12)

                                // Dish cards
                                ForEach(items) { item in
                                    NavigationLink(destination: DishDetailView(item: item)) {
                                        MenuDishCard(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .background(Color(.systemGroupedBackground).ignoresSafeArea())
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

// MARK: - MenuDishCard

struct MenuDishCard: View {
    let item: MenuItem

    var body: some View {
        HStack(spacing: 12) {
            FoodAvatar(item: item)
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(item.name)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.primary)
                    Spacer()
                    if let c = item.carbon {
                        Image(systemName: c == "low" ? "leaf.fill" : c == "medium" ? "exclamationmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(c == "low" ? .green : c == "medium" ? .orange : .red)
                    }
                }
                Text(item.station)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 10) {
                    Label("\(Int(item.nutrition.kcal)) kcal", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Label("\(Int(item.nutrition.proteinG))g P", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(Color(red:0.10,green:0.48,blue:0.92))
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}

// MARK: - MenuItemRow (kept for compatibility)

struct MenuItemRow: View {
    let item: MenuItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            FoodAvatar(item: item)
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
                    Label(item.station, systemImage: "tray.full")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(item.nutrition.kcal)) kcal")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                Text(item.diningHallPortionText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                FlowLayout(spacing: 4) {
                    ForEach(item.dietFlags, id: \.self) { flag in
                        DietBadge(flag: flag)
                    }
                }
            }
        }
        .padding(.vertical, 4)
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
