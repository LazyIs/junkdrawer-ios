import SwiftUI
import PhotosUI // Needed for PHPickerViewController

// MARK: - Data Models (Enums)

enum ItemCondition: String, CaseIterable, Identifiable {
    case new, good, fair, needsRepair

    var id: String { self.rawValue }

    var displayString: String {
        switch self {
        case .new:
            return NSLocalizedString("Condition_New", comment: "Item condition: New")
        case .good:
            return NSLocalizedString("Condition_Good", comment: "Item condition: Good")
        case .fair:
            return NSLocalizedString("Condition_Fair", comment: "Item condition: Fair")
        case .needsRepair:
            return NSLocalizedString("Condition_Needs_Repair", comment: "Item condition: Needs Repair")
        }
    }
}

enum ItemType: String, CaseIterable, Identifiable {
    case free, suggestedDonation, makeOffer

    var id: String { self.rawValue }

    var displayString: String {
        switch self {
        case .free:
            return NSLocalizedString("Type_Free", comment: "Item type: Free")
        case .suggestedDonation:
            return NSLocalizedString("Type_Suggested_Donation", comment: "Item type: Suggested Donation")
        case .makeOffer:
            return NSLocalizedString("Type_Make_Offer", comment: "Item type: Make Offer")
        }
    }
}

// MARK: - Add Item View

struct AddItemView: View {

    // MARK: State Variables
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker: Bool = false
    @State private var itemTitle: String = "" // Start empty, could be auto-generated later
    @State private var selectedCondition: ItemCondition = .good // Default condition
    @State private var itemNotes: String = ""
    @State private var selectedItemType: ItemType = .free // Default type

    // Placeholder for notes TextEditor
    private let notesPlaceholder = NSLocalizedString("Notes_Placeholder", comment: "Placeholder text for item notes")

    // MARK: Body
    var body: some View {
        // Use NavigationView for title and potential future navigation stack
        NavigationView {
            // Form provides standard iOS styling for input screens
            Form {
                // --- Image Section ---
                Section(header: Text(NSLocalizedString("Photo_Section_Header", comment: "Header for photo section"))) {
                    VStack(alignment: .center, spacing: 15) {
                        // Image Preview
                        ZStack {
                            // Placeholder
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(height: 200) // Define a reasonable height
                                .overlay(
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.largeTitle)
                                        .foregroundColor(Color(.systemGray2))
                                        .accessibilityLabel(NSLocalizedString("Placeholder_Image_Accessibility_Label", comment: "Accessibility label for placeholder image"))
                                )

                            // Selected Image
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200) // Limit height
                                    .clipShape(RoundedRectangle(cornerRadius: 8)) // Clip to bounds
                            }
                        }

                        // Button to trigger image picker
                        Button {
                            showImagePicker = true
                        } label: {
                            Label(NSLocalizedString("Select_Photo_Button", comment: "Button label: Select Photo"), systemImage: "photo.badge.plus")
                        }
                        .buttonStyle(.bordered) // Give it some visual style
                    }
                    .frame(maxWidth: .infinity) // Center content horizontally
                }

                // --- Details Section ---
                Section(header: Text(NSLocalizedString("Details_Section_Header", comment: "Header for item details section"))) {
                    // Title
                    TextField(
                        NSLocalizedString("Title_Placeholder", comment: "Placeholder text for item title"),
                        text: $itemTitle
                    )

                    // Condition Picker
                    Picker(
                        NSLocalizedString("Condition_Picker_Label", comment: "Label for item condition picker"),
                        selection: $selectedCondition
                    ) {
                        ForEach(ItemCondition.allCases) { condition in
                            Text(condition.displayString).tag(condition)
                        }
                    }
                    .pickerStyle(.segmented) // Use segmented style as requested

                    // Notes (Optional)
                    VStack(alignment: .leading) {
                         Text(NSLocalizedString("Notes_Label", comment: "Label for optional item notes"))
                             .font(.caption) // Smaller label for notes
                             .foregroundColor(.secondary)
                         TextEditor(text: $itemNotes)
                             .frame(height: 80) // Give it a defined height
                             .overlay(
                                 RoundedRectangle(cornerRadius: 5)
                                     .stroke(Color(.systemGray4), lineWidth: 1) // Subtle border
                             )
                             // Add placeholder text behavior for TextEditor
                             .background(
                                 Text(itemNotes.isEmpty ? notesPlaceholder : "")
                                     .foregroundColor(Color(.placeholderText))
                                     .padding(.horizontal, 5)
                                     .padding(.vertical, 8),
                                 alignment: .topLeading
                             )
                             .accessibilityLabel(notesPlaceholder)
                    }
                     .padding(.vertical, 5)


                }

                // --- Item Type Section ---
                Section(header: Text(NSLocalizedString("Listing_Type_Section_Header", comment: "Header for listing type section"))) {
                    Picker(
                        NSLocalizedString("Item_Type_Picker_Label", comment: "Label for item type picker"),
                        selection: $selectedItemType
                    ) {
                        ForEach(ItemType.allCases) { type in
                            Text(type.displayString).tag(type)
                        }
                    }
                    .pickerStyle(.segmented) // Use segmented style as requested
                }

                // --- Action Button Section ---
                Section {
                    // In a real app, this would likely save the item details
                    NavigationLink {
                        // Navigate to the DropOffDetailsView after adding basic info
                        DropOffDetailsView() // Pass necessary item data if needed
                    } label: {
                        Text(NSLocalizedString("Continue_Button", comment: "Button label: Continue"))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.borderedProminent) // Make it stand out
                    .disabled(isContinueDisabled()) // Disable if required fields missing
                }
                .listRowInsets(EdgeInsets()) // Allow button to potentially span width

            }
            .navigationTitle(NSLocalizedString("Add_Item_Screen_Title", comment: "Navigation bar title for Add Item screen"))
            .navigationBarTitleDisplayMode(.inline)
            // Sheet modifier to present the image picker
            .sheet(isPresented: $showImagePicker) {
                PhotoPicker(selectedImage: $selectedImage)
            }
        }
        // On smaller devices, prevent Nav title from becoming large
        .navigationViewStyle(.stack)
    }

    // MARK: - Helper Functions

    // Determine if the continue button should be disabled
    private func isContinueDisabled() -> Bool {
        // Require at least an image and a title to continue
        return selectedImage == nil || itemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Action to perform when continue button is tapped (handled by NavigationLink now)
    // private func continueAction() { }
}

// MARK: - Photo Picker (UIViewControllerRepresentable Wrapper)

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss // Use dismiss environment value

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images // Only allow images
        config.selectionLimit = 1 // Only allow one image selection
        config.preferredAssetRepresentationMode = .current // Get the best representation

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator // Set the delegate
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No update needed here for this simple case
    }

    // MARK: Coordinator
    // Acts as the delegate for the PHPickerViewController
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Dismiss the picker
            parent.dismiss()

            guard let provider = results.first?.itemProvider else { return }

            // Check if the provider can load a UIImage
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                     // Update the state on the main thread
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                        if let error = error {
                            print("Error loading image: \(error.localizedDescription)")
                            // Consider showing an alert to the user
                        }
                    }
                }
            } else {
                 print("Cannot load UIImage from provider.")
                 // Consider showing an alert to the user
            }
        }
    }
}

// MARK: - Preview Provider

struct AddItemView_Previews: PreviewProvider {
    static var previews: some View {
        AddItemView()
    }
}
