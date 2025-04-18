import SwiftUI
import Foundation // Needed for DateFormatter

// MARK: - Dummy Data Structure (Optional but helpful)

struct DummyItem {
    let title: String = NSLocalizedString("DummyItem_Title", comment: "Placeholder title for a giveaway item")
    let imageName: String = "shippingbox.fill" // SF Symbol for placeholder
    let pickupLocationDescription: String = NSLocalizedString("DummyItem_Location", comment: "Placeholder pickup location description")
    let pickupWindow: String // Calculated dynamically

    init() {
        // Generate a pickup window for today dynamically
        let now = Date()
        // Example: Pick up between 1-2 hours from now
        let startTime = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
        let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short // e.g., "7:00 PM"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium // e.g., "Apr 16, 2025"
        dateFormatter.timeStyle = .none

        // Use today/tomorrow relative formatting if possible
        let todayString: String
        if Calendar.current.isDateInToday(startTime) {
            todayString = NSLocalizedString("RelativeDate_Today", comment: "Relative date: today")
        } else if Calendar.current.isDateInTomorrow(startTime) {
            todayString = NSLocalizedString("RelativeDate_Tomorrow", comment: "Relative date: tomorrow")
        } else {
            todayString = dateFormatter.string(from: startTime)
        }

        let startTimeString = timeFormatter.string(from: startTime)
        let endTimeString = timeFormatter.string(from: endTime)

        // Format: "Pick up by 7:00 PM – 8:00 PM today" or "Pick up by 7:00 PM – 8:00 PM Apr 17, 2025"
        self.pickupWindow = String(format: NSLocalizedString("PickupWindow_Format", comment: "Format string for pickup window. Parameters: {Start Time}, {End Time}, {Date/Relative Day}"),
                                   startTimeString, endTimeString, todayString)
    }
}

// MARK: - Placeholder Map View

struct MapPlaceholderView: View {
    let locationDescription: String

    var body: some View {
        ZStack {
            // Simple visual placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            VStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text(NSLocalizedString("Map_Placeholder_Title", comment: "Title overlay on map placeholder"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(locationDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .accessibilityElement(children: .combine) // Combine elements for accessibility
            .accessibilityLabel(String(format: NSLocalizedString("Map_Placeholder_Accessibility_Label", comment: "Accessibility label for map placeholder. Parameter: {Location Description}"), locationDescription))

        }
        .frame(height: 200) // Give the placeholder a defined height
    }
}

// MARK: - Main Pickup Confirmation View

struct PickupConfirmationView: View {

    // MARK: State Variables
    @State private var item: DummyItem = DummyItem() // Load dummy data
    @State private var showProposeAlternateModal: Bool = false
    @State private var showConfirmationAlert: Bool = false
    @State private var isPickupConfirmed: Bool = false // Track confirmation state

    // MARK: Body
    var body: some View {
        // It's good practice to embed screens in NavigationView,
        // especially if they might present modals or navigate further.
        NavigationView {
            ScrollView { // Use ScrollView for potentially varying content height
                VStack(alignment: .leading, spacing: 20) {

                    // 1. Map View Placeholder
                    MapPlaceholderView(locationDescription: item.pickupLocationDescription)
                        .padding(.horizontal) // Add horizontal padding

                    Divider()

                    // 2. Item Title and Photo
                    HStack(spacing: 15) {
                        Image(systemName: item.imageName)
                            .font(.system(size: 50))
                            .frame(width: 70, height: 70)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(.accentColor)
                             .accessibilityHidden(true) // Hide decorative image from accessibility

                        VStack(alignment: .leading) {
                             Text(NSLocalizedString("Item_To_Pickup_Label", comment: "Label indicating the item to pick up"))
                                 .font(.caption)
                                 .foregroundColor(.secondary)
                            Text(item.title)
                                .font(.headline)
                                .lineLimit(2) // Prevent excessively long titles from breaking layout
                        }
                         .accessibilityElement(children: .combine)
                         .accessibilityLabel(item.title) // Combine title elements for accessibility

                        Spacer() // Push content to the left
                    }
                    .padding(.horizontal)

                    Divider()

                    // 3. Pickup Window
                    VStack(alignment: .leading) {
                        Label(NSLocalizedString("Pickup_Window_Label", comment: "Label for the pickup window section"), systemImage: "calendar.badge.clock")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(item.pickupWindow)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal)

                    Spacer() // Push buttons towards the bottom if content is short

                } // End VStack
                .padding(.bottom, 20) // Add padding below content before buttons

            } // End ScrollView
            // Place buttons outside ScrollView if they should always be visible
            .safeAreaInset(edge: .bottom) {
                 // 4. Action Buttons
                 HStack(spacing: 15) {
                     // Propose Alternate Button
                     Button {
                         showProposeAlternateModal = true
                     } label: {
                         Label(NSLocalizedString("Propose_Alternate_Button", comment: "Button: Propose Alternate"), systemImage: "clock.arrow.2.circlepath")
                             .frame(maxWidth: .infinity) // Make button take available space
                     }
                     .buttonStyle(.bordered) // Secondary style
                     .disabled(isPickupConfirmed) // Disable if already confirmed

                     // Confirm Pickup Button
                     Button {
                         // Trigger local success state
                         isPickupConfirmed = true
                         showConfirmationAlert = true
                         print("Pickup Confirmed!")
                         // In a real app, you might update server state here
                     } label: {
                         Label(NSLocalizedString("Confirm_Pickup_Button", comment: "Button: Confirm Pickup"), systemImage: "checkmark.circle.fill")
                             .frame(maxWidth: .infinity) // Make button take available space
                     }
                     .buttonStyle(.borderedProminent) // Primary style
                     .disabled(isPickupConfirmed) // Disable if already confirmed
                 }
                 .padding() // Add padding around the buttons
                 .background(.bar) // Use a bar background for semantic correctness
            }
            .navigationTitle(NSLocalizedString("Pickup_Details_Screen_Title", comment: "Navigation bar title for Pickup Details screen"))
            .navigationBarTitleDisplayMode(.inline)
            // Modal Sheet Presentation
            .sheet(isPresented: $showProposeAlternateModal) {
                // Present the ProposeAlternatePickupView modally
                ProposeAlternatePickupView()
            }
            // Alert Presentation
            .alert(isPresented: $showConfirmationAlert) {
                Alert(
                    title: Text(NSLocalizedString("Confirmation_Alert_Title", comment: "Alert title for successful pickup confirmation")),
                    message: Text(NSLocalizedString("Confirmation_Alert_Message", comment: "Alert message for successful pickup confirmation")),
                    dismissButton: .default(Text(NSLocalizedString("OK_Button", comment: "Standard OK button text"))) {
                        print("Confirmation alert dismissed.")
                    }
                )
            }
        }
        .navigationViewStyle(.stack) // Use stack style for consistent navigation appearance
    }
}

// MARK: - Preview Provider

struct PickupConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        PickupConfirmationView()
    }
}
