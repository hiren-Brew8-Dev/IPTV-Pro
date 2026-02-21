import SwiftUI
import CoreData

struct AddPlaylistView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var viewModel: PlaylistViewModel

    @State private var name: String = ""
    @State private var url: String = ""
    @State private var selectedType = "m3u"

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: PlaylistViewModel(context: context))
    }

    // Default init for preview or generic usage if needed, but context is required
    init() {
        // This won't essentially work well without context injection,
        // strictly relying on the one passed in Init with context.
        // But for .sheet call site:
        // We need to initialize it with context from Environment if possible,
        // but StateObject is initialized at init.
        // A better pattern: Pass ViewModel or Context.
        // For simplicity in this step, I'll rely on the parent creating it or passing context.
        // Actually best practice: use .environmentObject or create in Init.
        // I will use a custom init that takes context.
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: PlaylistViewModel(context: context))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Playlist Details")) {
                    TextField("Playlist Name", text: $name)

                    Picker("Type", selection: $selectedType) {
                        Text("M3U URL").tag("m3u")
                        Text("Xtream Codes").tag("xtream")
                    }
                    .pickerStyle(.segmented)

                    if selectedType == "m3u" {
                        TextField("M3U URL", text: $url)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    } else {
                        // Xtream fields placeholder
                        Text("Xtream support coming soon")
                            .foregroundColor(.gray)
                    }
                }

                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Parsing playlist...")
                        Spacer()
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add New Playlist")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            let success = await viewModel.addPlaylist(
                                name: name, urlString: url, type: selectedType)
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(
                        name.isEmpty || (selectedType == "m3u" && url.isEmpty)
                            || viewModel.isLoading)
                }
            }
        }
    }
}
