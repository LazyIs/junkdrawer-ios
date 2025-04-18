
import Foundation

// Represents the data structure for a proposal, matching the Supabase table
struct Proposal: Decodable, Identifiable {
    let id: Int // Assuming 'id' is an integer primary key in Supabase
    let createdAt: Date
    let location: String
    let startTime: Date
    let endTime: Date
    // Decode fee as Double? for easier JSON handling.
    let fee: Double?
    let giverId: String? // Assuming UUID stored as String (e.g., from auth.users)
    let acquirerId: String? // Assuming UUID stored as String (e.g., from auth.users)
    // TODO: Add other relevant fields from your 'proposals' table (e.g., item_id, status)

    // Computed property if you need Decimal precision elsewhere
    var feeDecimal: Decimal? {
        guard let fee = fee else { return nil }
        return Decimal(fee)
    }

    // Maps Swift camelCase properties to Supabase snake_case column names
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case location
        case startTime = "start_time"
        case endTime = "end_time"
        case fee
        case giverId = "giver_id"
        case acquirerId = "acquirer_id"
        // TODO: Add CodingKeys for other fields if added above
    }
}
