import SwiftUI

struct IntentInputSheet: View {
    @ObservedObject var viewModel: EventHubViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var intentText: String = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("What do you want to learn or find today?")
                    .font(.title3.bold())
                    .padding(.top)

                TextEditor(text: $intentText)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.systemGray4)
                    )
                    .overlay(alignment: .topLeading) {
                        if intentText.isEmpty {
                            Text("e.g. I want to learn about RAG pipelines")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(8)
                                .allowsHitTesting(false)
                        }
                    }
                    .onChange(of: intentText) { _, newValue in
                        if newValue.count > 280 { intentText = String(newValue.prefix(280)) }
                    }

                Text("\(intentText.count)/280")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button {
                    Task { await submitIntent() }
                } label: {
                    Text("Set Intent")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple, in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(intentText.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)

                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Set Intent")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                intentText = viewModel.intentText
            }
        }
    }

    private func submitIntent() async {
        isSubmitting = true
        await viewModel.setIntent(intentText.trimmingCharacters(in: .whitespaces))
        isSubmitting = false
        dismiss()
    }
}
