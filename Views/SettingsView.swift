import SwiftUI

// MARK: - Helper Structures

// Represents a selectable language
struct AppLanguage: Identifiable, Hashable {
    let id = UUID() // Conformance to Identifiable for ForEach
    let code: String // ISO language code (e.g., "en", "es")
    let name: String // Localized display name (e.g., "English", "Español")
}

// MARK: - Settings View

struct SettingsView: View {

    // MARK: Persistent Storage (@AppStorage)
    // Note: In a real app, changing language via AppStorage might require restarting
    // the app or using a more sophisticated localization manager to update UI instantly.
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode: String = Locale.current.language.languageCode?.identifier ?? "en"
    @AppStorage("pickupRadius") private var pickupRadius: Double = 5.0 // Default 5.0 miles
    @AppStorage("isEncryptionEnabled") private var isEncryptionEnabled: Bool = false // Default off

    // MARK: Static Data
    // Define available languages (add more as needed)
    private let availableLanguages: [AppLanguage] = [
        AppLanguage(code: "en", name: NSLocalizedString("Language_English", comment: "Language Name: English")),
        AppLanguage(code: "es", name: NSLocalizedString("Language_Spanish", comment: "Language Name: Spanish")),
        AppLanguage(code: "fr", name: NSLocalizedString("Language_French", comment: "Language Name: French"))
        // Potentially add system language option:
        // AppLanguage(code: "system", name: NSLocalizedString("Language_System_Default", comment: "Language Name: System Default"))
    ]

    // MARK: Computed Properties
    // Format the radius for display
    private var formattedRadius: String {
        // Format to one decimal place and add localized unit
        String(format: NSLocalizedString("Radius_Format", comment: "Format string for radius display. Parameter: {Distance Value (%.1f)}, {Unit (e.g., miles)}"),
               pickupRadius,
               NSLocalizedString("Distance_Unit_Miles", comment: "Distance unit: miles"))
    }

    // MARK: Body
    var body: some View {
        NavigationView {
            Form {
                // --- Preferences Section ---
                Section(header: Text(NSLocalizedString("Settings_Section_Preferences", comment: "Header for Preferences section"))) {

                    // 1. Language Selector
                    Picker(NSLocalizedString("Settings_Language_Label", comment: "Label for Language picker"), selection: $selectedLanguageCode) {
                        ForEach(availableLanguages) { language in
                            Text(language.name).tag(language.code) // Tag must match the type of selectedLanguageCode (String)
                        }
                    }
                    .accessibilityHint(NSLocalizedString("Settings_Language_Accessibility_Hint", comment: "Accessibility hint for language picker"))


                    // 2. Pickup Radius Slider
                    VStack(alignment: .leading) {
                        // Label shows the current value dynamically
                        Text(NSLocalizedString("Settings_Radius_Label", comment: "Label for Pickup Radius slider") + ": \(formattedRadius)")

                        Slider(
                            value: $pickupRadius,
                            in: 0.5...10.0, // Range from 0.5 to 10.0
                            step: 0.5       // Increment/decrement by 0.5
                        ) {
                           // This label is often not directly visible but used for accessibility
                           Text(NSLocalizedString("Settings_Radius_Slider_Accessibility_Label", comment: "Accessibility label for the radius slider itself"))
                        } minimumValueLabel: {
                           Text("0.5") // Accessibility label for minimum value
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } maximumValueLabel: {
                            Text("10.0") // Accessibility label for maximum value
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityValue(formattedRadius) // Read out the current formatted value
                    }
                    // Add padding within the VStack for better spacing if needed
                    .padding(.vertical, 4)


                    // 3. Encryption Toggle
                    Toggle(
                        NSLocalizedString("Settings_Encryption_Label", comment: "Label for Encryption toggle"),
                        isOn: $isEncryptionEnabled
                    )
                    .accessibilityHint(NSLocalizedString("Settings_Encryption_Accessibility_Hint", comment: "Accessibility hint for encryption toggle"))

                } // End Preferences Section

                // --- Account Section ---
                Section(header: Text(NSLocalizedString("Settings_Section_Account", comment: "Header for Account section"))) {
                    // 4. Sign Out Button
                    Button(role: .destructive) { // Use destructive role for sign out/delete actions
                        signOutAction()
                    } label: {
                        // Center the text within the button row
                        HStack {
                             Spacer()
                             Text(NSLocalizedString("Settings_Sign_Out_Button", comment: "Button label: Sign Out"))
                             Spacer()
                        }
                    }
                } // End Account Section

            } // End Form
            .navigationTitle(NSLocalizedString("Settings_Screen_Title", comment: "Navigation bar title for Settings screen"))
            .navigationBarTitleDisplayMode(.inline) // Use inline title display
        }
        // Use stack style to prevent large titles if not desired on settings
        .navigationViewStyle(.stack)
    }

    // MARK: - Actions
    private func signOutAction() {
        // Placeholder action - in a real app, this would clear credentials,
        // navigate to login screen, call Supabase auth signout, etc.
        print("Sign Out button tapped at \(Date())")
        // Example: Task { await supabaseClient.auth.signOut() }
    }
}

// MARK: - Preview Provider

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
