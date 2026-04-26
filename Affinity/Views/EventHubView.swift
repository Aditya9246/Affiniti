import SwiftUI

struct EventHubView: View {
    let event: Event
    @StateObject private var viewModel: EventHubViewModel

    init(event: Event) {
        self.event = event
        _viewModel = StateObject(wrappedValue: EventHubViewModel(event: event))
    }

    var body: some View {
        TabView {
            DiscoveryFeedTab(viewModel: viewModel)
                .tabItem {
                    Label("Feed", systemImage: "rectangle.stack.fill")
                }

            MatchesTab(viewModel: viewModel)
                .tabItem {
                    Label("Matches", systemImage: "sparkles")
                }

            ToMeetTab(viewModel: viewModel)
                .tabItem {
                    Label("To Meet", systemImage: "bookmark.fill")
                }

            MyStatusTab(viewModel: viewModel)
                .tabItem {
                    Label("My Status", systemImage: "circle.fill")
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
