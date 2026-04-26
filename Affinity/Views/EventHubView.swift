import SwiftUI

enum HubTab: String, CaseIterable {
    case feed = "Feed"
    case matches = "Matches"
    case toMeet = "To Meet"
    case status = "My Status"
}

struct EventHubView: View {
    let event: Event
    @StateObject private var viewModel: EventHubViewModel
    @State private var selectedTab: HubTab = .feed

    init(event: Event) {
        self.event = event
        _viewModel = StateObject(wrappedValue: EventHubViewModel(event: event))
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedTab) {
                ForEach(HubTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch selectedTab {
            case .feed:
                DiscoveryFeedTab(viewModel: viewModel)
            case .matches:
                MatchesTab(viewModel: viewModel)
            case .toMeet:
                ToMeetTab(viewModel: viewModel)
            case .status:
                MyStatusTab(viewModel: viewModel)
            }
        }
        .tint(.purple)
        .navigationTitle(event.name)
        .inlineNavigationBarTitle()
        .task {
            await viewModel.loadAll()
        }
    }
}
