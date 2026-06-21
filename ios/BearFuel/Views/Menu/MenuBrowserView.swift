import SwiftUI

struct MenuBrowserView: View {
    @StateObject private var vm = MenuViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                CampusBackdrop(intensity: 0.75)
                content
            }
            .navigationTitle("Menu")
            .searchable(text: $vm.searchText, prompt: "Search dishes")
            .task { await vm.load() }
            .refreshable { await vm.refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading && vm.items.isEmpty {
            loadingState
        } else if vm.groupedItems.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    menuHero
                    locationFilter

                    ForEach(Array(vm.groupedItems.enumerated()), id: \.element.0) { index, group in
                        MenuStationSection(station: group.0, items: group.1, index: index)
                    }
                }
                .padding(16)
                .padding(.bottom, 18)
            }
        }
    }

    private var loadingState: some View {
        BerkeleyCard(padding: 24) {
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.berkeleyBlue)
                Text("Loading today's menu")
                    .font(.headline)
                Text("Checking Berkeley dining halls for the latest options.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(24)
    }

    private var emptyState: some View {
        BerkeleyCard(padding: 24) {
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(BerkeleyTheme.vibrantGradient)
                Text("No Dishes Found")
                    .font(.headline)
                Text("Try another dining hall or search term.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(24)
    }

    private var menuHero: some View {
        GradientCardView(gradient: BerkeleyTheme.vibrantGradient) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 160, height: 52)
                    .rotationEffect(.degrees(18))
                    .offset(x: 94, y: -38)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.berkeleyGold.opacity(0.22))
                    .frame(width: 108, height: 42)
                    .rotationEffect(.degrees(-22))
                    .offset(x: 110, y: 40)

                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Berkeley Dining")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.85))
                            Text(vm.selectedLocation == "All" ? "Today's Menu" : vm.selectedLocation)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(.berkeleyGold)
                    }

                    HStack(spacing: 10) {
                        MenuHeroMetric(icon: "takeoutbag.and.cup.and.straw.fill", value: "\(vm.filteredItems.count)", label: "dishes")
                        MenuHeroMetric(icon: "square.grid.2x2.fill", value: "\(vm.groupedItems.count)", label: "stations")
                        MenuHeroMetric(icon: vm.isShowingFallback ? "wifi.slash" : "checkmark.seal.fill", value: vm.isShowingFallback ? "demo" : "live", label: "menu")
                    }
                }
                .padding(20)
            }
        }
        .cardEntrance(delay: 0.04)
    }

    private var locationFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.locations, id: \.self) { location in
                    SelectionChip(
                        title: displayLocation(location),
                        icon: location == "All" ? "globe.americas.fill" : "mappin.circle.fill",
                        isSelected: vm.selectedLocation == location,
                        color: location == "All" ? .berkeleyBlue : .bayBlue
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
                            vm.selectedLocation = location
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .cardEntrance(delay: 0.08)
    }

    private func displayLocation(_ location: String) -> String {
        switch location {
        case "Cafe3": return "Cafe 3"
        case "ClarkKerr": return "Clark Kerr"
        default: return location
        }
    }
}

private struct MenuHeroMetric: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
            Text(value)
                .font(.headline.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption2.weight(.semibold))
                .opacity(0.82)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct MenuStationSection: View {
    let station: String
    let items: [MenuItem]
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                BerkeleySectionHeader(
                    title: station,
                    subtitle: "\(items.count) dishes",
                    icon: "tray.full.fill"
                )
                Spacer()
            }

            VStack(spacing: 10) {
                ForEach(items) { item in
                    NavigationLink(destination: DishDetailView(item: item)) {
                        MenuDishCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardEntrance(delay: 0.11 + Double(index) * 0.025)
    }
}

// MARK: - MenuDishCard

struct MenuDishCard: View {
    let item: MenuItem

    var body: some View {
        BerkeleyCard(padding: 14, radius: 18) {
            HStack(alignment: .top, spacing: 12) {
                FoodAvatar(item: item)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(item.name)
                            .font(.subheadline.bold())
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(.primary)
                        Spacer(minLength: 4)
                        carbonBadge
                    }

                    HStack(spacing: 6) {
                        Label(item.station, systemImage: "tray.full")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text(item.diningHallPortionText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    FlowLayout(spacing: 6) {
                        MetricPill(icon: "flame.fill", title: "Calories", value: "\(Int(item.nutrition.kcal)) kcal", color: .orange)
                            .frame(width: 132)
                        MetricPill(icon: "bolt.fill", title: "Protein", value: "\(Int(item.nutrition.proteinG))g", color: .berkeleyBlue)
                            .frame(width: 118)
                        ForEach(item.dietFlags.prefix(3), id: \.self) { flag in
                            DietBadge(flag: flag)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var carbonBadge: some View {
        if let carbon = item.carbon {
            let color = carbon == "low" ? Color.campusMint : carbon == "medium" ? Color.berkeleyGold : Color.poppy
            Image(systemName: carbon == "low" ? "leaf.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
        }
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
            let color: Color = carbon == "low" ? .campusMint : carbon == "medium" ? .berkeleyGold : .poppy
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .help("Carbon footprint: \(carbon)")
        }
    }
}
