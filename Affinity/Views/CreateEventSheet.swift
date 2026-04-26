import SwiftUI
import PhotosUI

struct CreateEventSheet: View {
    @ObservedObject var viewModel: EventListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var description = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var coverImageData: Data?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Name *", text: $name)
                        .accessibilityLabel("Event name, required")

                    DatePicker("Date & Time", selection: $date)
                        .accessibilityLabel("Event date and time")

                    TextField("Location", text: $location)
                        .accessibilityLabel("Event location")
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }

                Section("Cover Image") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text(coverImageData == nil ? "Choose Cover Image" : "Change Image")
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                coverImageData = data
                            }
                        }
                    }

                    if coverImageData != nil {
                        Text("Image selected")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Create Event")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await createEvent() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                    .bold()
                }
            }
        }
    }

    private func createEvent() async {
        isSubmitting = true
        let request = CreateEventRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            date: date,
            location: location,
            description: description.isEmpty ? nil : description,
            coverImageBase64: coverImageData?.base64EncodedString()
        )
        let success = await viewModel.createEvent(request)
        if success {
            dismiss()
        }
        isSubmitting = false
    }
}
