import SwiftUI

extension View {
    @ViewBuilder
    func inlineNavigationBarTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func noAutocapitalization() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }
}

extension Color {
    static var systemBackground: Color {
        #if os(iOS)
        Color(uiColor: .systemBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var systemGray6: Color {
        #if os(iOS)
        Color(uiColor: .systemGray6)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    static var systemGray4: Color {
        #if os(iOS)
        Color(uiColor: .systemGray4)
        #else
        Color(nsColor: .separatorColor)
        #endif
    }
}
