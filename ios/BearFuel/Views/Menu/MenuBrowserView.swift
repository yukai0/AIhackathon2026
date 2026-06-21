import SwiftUI

struct MenuBrowserView: View {
    @StateObject private var vm = MenuViewModel()

    var body: some View {
        ZStack {
            BerkeleyBackground()
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
                            LazyVStack(spacing: 12, pinnedViews: []) {
                                ForEach(vm.groupedItems, id: \.0) { station, items in
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Station header
                                        HStack {
                                            Text(station)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(Color.berkeleyGold)
                                            Spacer()
                                            Text("\(items.count) dishes")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 4)
                                        .padding(.top, 8)

                                        // Items
                                        ForEach(items) { item in
                                            NavigationLink(destination: DishDetailView(item: item)) {
                                                MenuItemRow(item: item)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                        .scrollContentBackground(.hidden)
                        .refreshable { await vm.refresh() }
                    }
                }
                .background(.clear)
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
            .colorScheme(.dark)
        }
    }
}

// MARK: - MenuItemRow

struct MenuItemRow: View {
    let item: MenuItem

    var body: some View {
        HStack(spacing: 14) {
            FoodAvatar(item: item)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    Spacer()
                    carbonBadge
                }
                Text(item.station)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    Label("\(Int(item.nutrition.kcal)) kcal", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Label("\(Int(item.nutrition.proteinG))g P", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.berkeleyBlue)
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.75)
        )
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.28), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var carbonBadge: some View {
        if let carbon = item.carbon {
            let (color, icon): (Color, String) = carbon == "low" ? (.green, "leaf.fill") :
                                                  carbon == "medium" ? (.orange, "exclamationmark.circle.fill") :
                                                  (.red, "exclamationmark.triangle.fill")
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
        }
    }
}
