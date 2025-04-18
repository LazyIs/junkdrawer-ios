import SwiftUI

struct ProposeAlternatePickupView: View {

    // MARK: - Environment
    @Environment(\.dismiss) var dismiss // Environment value to dismiss the modal

    // MARK: - State Variables
    @State private var proposedLocation: String = ""
    // Initialize dates to be slightly in the future for better UX
    @State private var proposedStartTime: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var proposedEndTime: Date = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    @State private var proposedFeeString: String = ""

    @State private var showingValidationErrorAlert = false
    @State private var validationErrorMessage = ""

    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // --- Location Section ---
                Section(header: Text(NSLocalizedString("Proposed_Location_Section_Header", comment: "Header for proposed location section"))) {
                    TextField(
                        NSLocalizedString("Location_Placeholder", comment: "Placeholder text for location field (e.g., address or landmark)"),
                        text: $proposedLocation
                    )
                     .accessibilityLabel(NSLocalizedString("Proposed_Location_Accessibility_Label", comment: "Accessibility label for the proposed location text field"))
                }

                // --- Time Window Section ---
                Section(header: Text(NSLocalizedString("Proposed_Time_Window_Section_Header", comment: "Header for proposed time window section"))) {
                    DatePicker(
                        NSLocalizedString("Start_Time_Label", comment: "Label for start time picker"),
                        selection: $proposedStartTime,
                        in: Date()..., // Allow selection from now onwards
                        displayedComponents: [.date, .hourAndMinute]
                    )
                     .accessibilityLabel(NSLocalizedString("Proposed_Start_Time_Accessibility_Label", comment: "Accessibility label for the proposed start time date picker"))


                    DatePicker(
                        NSLocalizedString("End_Time_Label", comment: "Label for end time picker"),
                        selection: $proposedEndTime,
                        // Ensure end time picker starts from the selected start time
                        in: proposedStartTime...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityLabel(NSLocalizedString("Proposed_End_Time_Accessibility_Label", comment: "Accessibility label for the proposed end time date picker"))
                    // Add a check to ensure end time is dynamically updated if start time changes
                    .onChange(of: proposedStartTime) { newStartTime in
                         if proposedEndTime < newStartTime {
                             // Automatically adjust end time if it becomes invalid (e.g., 1 hour after new start)
                             proposedEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newStartTime) ?? newStartTime
                         }
                     }

                    // Helper text explaining the time range purpose
                    Text(NSLocalizedString("Time_Window_Explanation", comment: "Explanation text below time pickers"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // --- Optional Fee Section ---
                Section(header: Text(NSLocalizedString("Optional_Fee_Section_Header", comment: "Header for optional fee section"))) {
                    HStack {
                        // Currency symbol (adjust if needed for other locales)
                         Text(NSLocalizedString("Currency_Symbol", comment: "Currency symbol, e.g., $"))
                            .foregroundColor(.secondary)
                        TextField(
                            NSLocalizedString("Fee_Placeholder", comment: "Placeholder text for fee amount, e.g., 5.00"),
                            text: $proposedFeeString
                        )
                        .keyboardType(.decimalPad) // Use decimal pad for currency input
                        .accessibilityLabel(NSLocalizedString("Proposed_Fee_Accessibility_Label", comment: "Accessibility label for the proposed fee text field"))
                    }
                }

                // --- Action Button Section ---
                Section {
                    Button {
                        sendProposalAction()
                    } label: {
                        Text(NSLocalizedString("Send_Proposal_Button_Modal", comment: "Button label: Send Proposal"))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.borderedProminent) // Make primary action prominent
                }
                 // .listRowInsets(EdgeInsets()) // Optional: remove padding

            }
            .navigationTitle(NSLocalizedString("Propose_Alternate_Modal_Title", comment: "Navigation bar title for Propose Alternate modal"))
            .navigationBarTitleDisplayMode(.inline) // Keep title compact in modal
            .toolbar {
                // Cancel Button in Toolbar
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel_Button", comment: "Button label: Cancel")) {
                        dismiss() // Dismiss the modal using the environment value
                    }
                }
            }
             // Alert for validation errors
            .alert(isPresented: $showingValidationErrorAlert) {
                Alert(
                    title: Text(NSLocalizedString("Validation_Error_Alert_Title", comment: "Title for validation error alert")),
                    message: Text(validationErrorMessage), // Display specific error
                    dismissButton: .default(Text(NSLocalizedString("OK_Button", comment: "Standard OK button text")))
                )
            }
        }
        // Use stack style if this modal might push other views (unlikely but possible)
        // .navigationViewStyle(.stack)
    }

    // MARK: - Helper Functions

    private func validateInput() -> Bool {
        // Ensure end time is strictly after start time
        // Allow end time to be equal to start time if needed, adjust logic accordingly (e.g., >=)
        guard proposedEndTime > proposedStartTime else {
             validationErrorMessage = NSLocalizedString("Validation_Error_End_Time", comment: "Error message: End time must be after start time.")
            showingValidationErrorAlert = true
            return false
        }

        // Optional: Validate fee input (ensure it's a valid number if entered)
        if !proposedFeeString.isEmpty {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
             if formatter.number(from: proposedFeeString) == nil {
                 validationErrorMessage = NSLocalizedString("Validation_Error_Invalid_Fee", comment: "Error message: Please enter a valid number for the fee.")
                 showingValidationErrorAlert = true
                 return false
             }
        }

        return true // All checks passed
    }

    private func sendProposalAction() {
        guard validateInput() else {
            return // Stop if validation fails
        }

        // Attempt to convert fee string to a Decimal (or Double)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let proposedFeeDecimal = formatter.number(from: proposedFeeString)?.decimalValue // Use decimalValue for currency

        // --- Print values (Placeholder Action) ---
        print("--- Proposal Details ---")
        print("Location: \(proposedLocation.isEmpty ? "Not Provided" : proposedLocation)")
        print("Start Time: \(proposedStartTime.formatted(date: .short, time: .short))")
        print("End Time: \(proposedEndTime.formatted(date: .short, time: .short))")
        if let fee = proposedFeeDecimal {
             print("Proposed Fee: \(fee)")
        } else {
            print("Proposed Fee: None")
        }
        print("------------------------")
        // --- End Placeholder Action ---

        // --- Call Supabase Service ---
        // In a real app, call the function to send data to Supabase
        Task {
            do {
                try await ProposalService.sendProposalToSupabase(
                    location: proposedLocation,
                    startTime: proposedStartTime,
                    endTime: proposedEndTime,
                    fee: proposedFeeDecimal
                )
                print("✅ Proposal successfully sent via service.")
                // Dismiss only on success
                await MainActor.run { // Ensure UI updates on main thread
                     dismiss()
                }
            } catch {
                print("❌ Failed to send proposal via service: \(error)")
                // Optionally show another alert here based on the specific error
                await MainActor.run { // Ensure UI updates on main thread
                    validationErrorMessage = String(format: NSLocalizedString("Proposal_Send_Error", comment: "Error message when sending proposal fails. Parameter: {Error Description}"), error.localizedDescription)
                    showingValidationErrorAlert = true // Re-use validation alert for send errors
                }
            }
        }
        // --- End Supabase Call ---

        // Don't dismiss here anymore, dismiss in the Task on success
        // dismiss()
    }
}

// MARK: - Preview Provider

struct ProposeAlternatePickupView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview the modal itself
        ProposeAlternatePickupView()
    }
}
