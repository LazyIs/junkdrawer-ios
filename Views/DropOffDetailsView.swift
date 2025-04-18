import SwiftUI

// MARK: - Data Model (Enum)

enum DropOffType: String, CaseIterable, Identifiable {
    case porchPickup, publicSpot, scheduledHandoff

    var id: String { self.rawValue }

    var displayString: String {
        switch self {
        case .porchPickup:
            return NSLocalizedString("DropOffType_Porch", comment: "Drop-off type option: Porch Pickup")
        case .publicSpot:
            return NSLocalizedString("DropOffType_Public", comment: "Drop-off type option: Public Spot")
        case .scheduledHandoff:
            return NSLocalizedString("DropOffType_Handoff", comment: "Drop-off type option: Scheduled Handoff")
        }
    }
}

// MARK: - Drop-off Details View

struct DropOffDetailsView: View {

    // MARK: State Variables
    @State private var selectedDropOffType: DropOffType = .porchPickup // Default selection
    @State private var locationInstructions: String = ""
    @State private var isAvailabilityWindowEnabled: Bool = false
    // Default availability to tomorrow at 9:00 AM if enabled
    @State private var availabilityDate: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Calendar.current.date(byAdding: .day, value: 1, to: Date())!) ?? Date()

    // Placeholder text for TextEditor
    private let instructionsPlaceholder = NSLocalizedString("Location_Instructions_Placeholder", comment: "Placeholder text for location instructions (e.g., By the front steps under the green bench)")

    // MARK: Body
    var body: some View {
        // No NavigationView needed if this view is pushed onto an existing navigation stack
        Form {
            // --- Drop-off Method Section ---
            Section(header: Text(NSLocalizedString("DropOff_Method_Section_Header", comment: "Header for Drop-off Method section"))) {

                // 1. Drop-off Type Picker
                Picker(NSLocalizedString("DropOff_Type_Picker_Label", comment: "Label for Drop-off Type picker"), selection: $selectedDropOffType) {
                    ForEach(DropOffType.allCases) { type in
                        Text(type.displayString).tag(type)
                    }
                }
                .accessibilityHint(NSLocalizedString("DropOff_Type_Picker_Accessibility_Hint", comment: "Accessibility hint for drop-off type picker"))


                // 2. Location Instructions TextEditor
                VStack(alignment: .leading) {
                     Text(NSLocalizedString("Location_Instructions_Label", comment: "Label for Location Instructions TextEditor"))
                         .font(.caption)
                         .foregroundColor(.secondary)

                     TextEditor(text: $locationInstructions)
                         .frame(height: 100) // Give it a reasonable height
                         .overlay(
                             RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(.systemGray4), lineWidth: 1) // Subtle border
                         )
                         // Add placeholder text behavior
                         .background(
                             Text(locationInstructions.isEmpty ? instructionsPlaceholder : "")
                                 .foregroundColor(Color(.placeholderText))
                                 .padding(.horizontal, 5)
                                 .padding(.vertical, 8),
                             alignment: .topLeading
                         )
                         .accessibilityLabel(instructionsPlaceholder) // Use placeholder as label if empty
                         .accessibilityHint(NSLocalizedString("Location_Instructions_Accessibility_Hint", comment: "Accessibility hint for location instructions editor"))

                }
                 // Add padding to separate from picker
                .padding(.vertical, 5)

            } // End Drop-off Method Section


            // --- Optional Availability Section ---
            Section(header: Text(NSLocalizedString("Availability_Section_Header", comment: "Header for Optional Availability section"))) {

                // 3. Toggle to enable DatePicker
                Toggle(
                    NSLocalizedString("Set_Availability_Toggle_Label", comment: "Label for Set Availability Window toggle"),
                    isOn: $isAvailabilityWindowEnabled.animation() // Animate showing/hiding picker
                )
                 .accessibilityHint(NSLocalizedString("Set_Availability_Toggle_Accessibility_Hint", comment: "Accessibility hint for availability toggle"))


                // 4. DatePicker (conditionally enabled)
                DatePicker(
                    NSLocalizedString("Availability_DatePicker_Label", comment: "Label for Availability DatePicker"),
                    selection: $availabilityDate,
                    in: Date()..., // Allow selection from now onwards
                    displayedComponents: [.date, .hourAndMinute]
                )
                .disabled(!isAvailabilityWindowEnabled) // Disable if toggle is off
                .opacity(isAvailabilityWindowEnabled ? 1.0 : 0.5) // Visually indicate disabled state
                .accessibilityHint(isAvailabilityWindowEnabled ? NSLocalizedString("Availability_DatePicker_Enabled_Hint", comment: "Accessibility hint when date picker is enabled") : NSLocalizedString("Availability_DatePicker_Disabled_Hint", comment: "Accessibility hint when date picker is disabled"))


                // Helper text explaining the purpose of the date/time
                if isAvailabilityWindowEnabled {
                    Text(getAvailabilityExplanationText())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

            } // End Optional Availability Section


            // --- Action Button Section ---
            Section {
                // 5. Continue Button (or maybe "Save" or "List Item")
                Button {
                    saveDropOffDetailsAction()
                } label: {
                    Text(NSLocalizedString("Save_DropOff_Button", comment: "Button label: Save Drop-off Details")) // Changed from Continue
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
                .disabled(disableSaveButton()) // Use validation logic

            }
             // .listRowInsets(EdgeInsets()) // Optional


        } // End Form
        .navigationTitle(NSLocalizedString("DropOff_Details_Screen_Title", comment: "Navigation bar title for Drop-off Details screen"))
        .navigationBarTitleDisplayMode(.inline) // Use inline for potentially longer titles
    }

    // MARK: - Helper Functions

    // Provides context-sensitive explanation text below the DatePicker
    private func getAvailabilityExplanationText() -> String {
        switch selectedDropOffType {
        case .porchPickup:
            return NSLocalizedString("Availability_Explanation_Porch", comment: "Explanation for availability date/time for Porch Pickup")
        case .publicSpot:
             return NSLocalizedString("Availability_Explanation_Public", comment: "Explanation for availability date/time for Public Spot")
        case .scheduledHandoff:
             return NSLocalizedString("Availability_Explanation_Handoff", comment: "Explanation for availability date/time for Scheduled Handoff")
        }
    }

    // Example logic to potentially disable the Save button
    private func disableSaveButton() -> Bool {
        // Require instructions for porch/public pickups?
        if selectedDropOffType != .scheduledHandoff && locationInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        // Require availability window for handoff?
        if selectedDropOffType == .scheduledHandoff && !isAvailabilityWindowEnabled {
             return true // Handoffs likely require a specific time
        }
        return false // Default to enabled if conditions met
    }


    private func saveDropOffDetailsAction() {
        print("--- Save Drop-off Details Tapped ---")
        print("Drop-off Type: \(selectedDropOffType.rawValue)")
        print("Instructions: \(locationInstructions.isEmpty ? "None" : locationInstructions)")
        if isAvailabilityWindowEnabled {
            print("Availability Set: \(availabilityDate.formatted(date: .long, time: .short))")
        } else {
            print("Availability Set: No")
        }
        print("------------------------------------")

        // TODO: Save these details along with the item information
        // This might involve updating an item record in Supabase or passing data back
        // to a previous view model.
    }
}

// MARK: - Preview Provider

struct DropOffDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        // Embed in NavigationView for preview context if needed
        NavigationView {
             DropOffDetailsView()
        }
    }
}
