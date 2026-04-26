import SwiftUI

struct MyStatusTab: View {
    @ObservedObject var viewModel: EventHubViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Set Your Status")
                    .font(.title2.bold())
                    .padding(.top, 24)

                Text("Let others know what you're up to")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    ForEach(AttendeeStatus.allCases, id: \.self) { status in
                        StatusCard(
                            status: status,
                            isSelected: viewModel.currentStatus == status
                        ) {
                            Task { await viewModel.setStatus(status) }
                        }
                    }
                }
                .padding(.horizontal)

                if let updatedAt = viewModel.statusUpdatedAt {
                    Text("Last updated \(updatedAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }
}

struct StatusCard: View {
    let status: AttendeeStatus
    let isSelected: Bool
    let onTap: () -> Void

    var statusColor: Color {
        switch status {
        case .openToChat: return .green
        case .lookingForGroup: return .blue
        case .deepInWork: return .red
        case .takingABreak: return .orange
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: status.icon)
                    .font(.title2)
                    .foregroundStyle(statusColor)
                    .frame(width: 44, height: 44)

                Text(status.rawValue)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? .purple.opacity(0.1) : Color.systemGray6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? .purple : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(status.rawValue)\(isSelected ? ", currently selected" : "")")
    }
}
