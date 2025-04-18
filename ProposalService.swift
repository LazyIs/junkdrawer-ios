import Foundation

// MARK: - Supabase Configuration (Updated)

// Using the provided URL and Anon Key
let SUPABASE_URL_STRING = "https://iliwrvyvsulblvzzeqob.supabase.co"
let SUPABASE_API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsaXdydnl2c3VsYmx2enplcW9iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4NjIxOTIsImV4cCI6MjA2MDQzODE5Mn0.0gUA9Ltm49wYeocVm6zn267cvSlBqxiySXz1HGQRC8M"

// IMPORTANT: This is still a placeholder. Replace with actual user JWT or Service Role Key.
// User JWTs are obtained after authentication. Service Role Keys grant admin access
// and should ONLY be used in secure backend environments, NEVER directly in a mobile app.
let SUPABASE_BEARER_TOKEN = "YOUR_USER_JWT_OR_SERVICE_ROLE_KEY_HERE"

// MARK: - Data Model

struct Proposal: Decodable, Identifiable {
    let id: Int // Assuming 'id' is an integer primary key in Supabase
    let createdAt: Date
    let location: String
    let startTime: Date
    let endTime: Date
    // Decode fee as Double? for easier JSON handling. Provide Decimal computed property if needed.
    let fee: Double?
    let giverId: String? // Assuming UUID stored as String
    let acquirerId: String? // Assuming UUID stored as String

    // Computed property if you need Decimal precision elsewhere
    var feeDecimal: Decimal? {
        guard let fee = fee else { return nil }
        return Decimal(fee)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at" // Map Swift camelCase to Supabase snake_case
        case location
        case startTime = "start_time"
        case endTime = "end_time"
        case fee
        case giverId = "giver_id"
        case acquirerId = "acquirer_id"
    }
}

// MARK: - Error Handling Enum

enum SupabaseError: Error, LocalizedError {
    case invalidURL
    case jsonEncodingError
    case jsonDecodingError(Error)
    case requestFailed(statusCode: Int, message: String?)
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("SupabaseError_InvalidURL", comment: "Error description: Invalid Supabase URL")
        case .jsonEncodingError:
            return NSLocalizedString("SupabaseError_JSONEncoding", comment: "Error description: Failed to encode JSON")
        case .jsonDecodingError(let underlyingError):
            return String(format: NSLocalizedString("SupabaseError_JSONDecoding", comment: "Error description: Failed to decode JSON. Parameter: {Underlying error description}"), underlyingError.localizedDescription)
        case .requestFailed(let statusCode, let message):
            let baseMessage = String(format: NSLocalizedString("SupabaseError_RequestFailed", comment: "Error description: Request failed. Parameters: {Status Code}, {Optional Server Message}"), statusCode)
            return message != nil ? "\(baseMessage) - \(message!)" : baseMessage
        case .networkError(let underlyingError):
            return String(format: NSLocalizedString("SupabaseError_Network", comment: "Error description: Network error. Parameter: {Underlying error description}"), underlyingError.localizedDescription)
        case .invalidResponse:
            return NSLocalizedString("SupabaseError_InvalidResponse", comment: "Error description: Invalid response received from server")
        }
    }
}

// Helper struct to decode potential error messages from Supabase
struct SupabaseErrorResponse: Decodable {
    let message: String
    let code: String?
    let hint: String?
    let details: String?
}


// MARK: - Proposal Service Logic

// Using a class or struct namespace for service functions
class ProposalService {

    /**
     Sends proposal data to a Supabase table named "proposals" via the REST API.

     - Parameters:
        - location: The proposed location string (e.g., address or landmark).
        - startTime: The proposed start date and time for the pickup window.
        - endTime: The proposed end date and time for the pickup window.
        - fee: An optional fee associated with the proposal.
     - Throws: `SupabaseError` detailing the reason for failure.
     */
    static func sendProposalToSupabase(
        location: String,
        startTime: Date,
        endTime: Date,
        fee: Decimal?
    ) async throws {

        // 1. Construct the URL
        guard let supabaseURL = URL(string: SUPABASE_URL_STRING),
              let endpointURL = URL(string: "/rest/v1/proposals", relativeTo: supabaseURL) else {
            print("Error: Invalid Supabase URL configuration.")
            throw SupabaseError.invalidURL
        }

        // 2. Format Dates to ISO8601 strings
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startTimeString = dateFormatter.string(from: startTime)
        let endTimeString = dateFormatter.string(from: endTime)

        // 3. Prepare Request Body (JSON)
        var proposalData: [String: Any] = [
            "location": location,
            "start_time": startTimeString,
            "end_time": endTimeString
            // Add giver_id if available from auth state: "giver_id": userUUID
        ]
        if let fee = fee {
            proposalData["fee"] = NSDecimalNumber(decimal: fee).doubleValue
        }

        // 4. Encode the body data
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: proposalData, options: [])
        } catch {
            print("Error: Failed to encode proposal data to JSON - \(error)")
            throw SupabaseError.jsonEncodingError
        }

        // 5. Create URLRequest
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"

        // 6. Set Headers
        request.setValue(SUPABASE_API_KEY, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SUPABASE_BEARER_TOKEN)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        // 7. Assign Body
        request.httpBody = jsonData

        // 8. Perform Network Request
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("Error: Network request failed - \(error)")
            throw SupabaseError.networkError(error)
        }

        // 9. Handle Response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Error: Invalid HTTP response received.")
            throw SupabaseError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            var errorMessage: String?
            if let decodedError = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) {
                errorMessage = decodedError.message
            }
            print("Error: Supabase request failed with status code \(httpResponse.statusCode). \(errorMessage ?? "No error details.")")
            throw SupabaseError.requestFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        print("Proposal successfully sent to Supabase!")
    }


    /**
     Fetches proposals from the Supabase "proposals" table, optionally filtering by acquirer ID.

     - Parameters:
        - acquirerID: An optional String representing the UUID of the acquirer to filter by.
                     If nil, fetches all proposals (respecting RLS policies).
     - Returns: An array of `Proposal` objects.
     - Throws: `SupabaseError` detailing the reason for failure.
     */
    static func fetchProposals(acquirerID: String? = nil) async throws -> [Proposal] {

        // 1. Construct Base URL Components
        guard let supabaseURL = URL(string: SUPABASE_URL_STRING),
              var components = URLComponents(url: supabaseURL.appendingPathComponent("/rest/v1/proposals"), resolvingAgainstBaseURL: false) else {
            print("Error: Invalid Supabase URL configuration.")
            throw SupabaseError.invalidURL
        }

        // 2. Prepare Query Parameters
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "select", value: "*"))

        if let id = acquirerID {
            queryItems.append(URLQueryItem(name: "acquirer_id", value: "eq.\(id)"))
        }
        // queryItems.append(URLQueryItem(name: "order", value: "created_at.desc")) // Optional sorting

        components.queryItems = queryItems

        // 3. Get Final URL
        guard let finalURL = components.url else {
            print("Error: Could not construct final URL with query parameters.")
            throw SupabaseError.invalidURL
        }

        // 4. Create URLRequest
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"

        // 5. Set Headers
        request.setValue(SUPABASE_API_KEY, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SUPABASE_BEARER_TOKEN)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // 6. Perform Network Request
        let data: Data
        let response: URLResponse
        do {
            print("Fetching proposals from: \(finalURL.absoluteString)")
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("Error: Network request failed - \(error)")
            throw SupabaseError.networkError(error)
        }

        // 7. Handle Response Status Code
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Error: Invalid HTTP response received.")
            throw SupabaseError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            var errorMessage: String?
            if let decodedError = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) {
                errorMessage = decodedError.message
            }
            print("Error: Supabase request failed with status code \(httpResponse.statusCode). \(errorMessage ?? "No error details.")")
            throw SupabaseError.requestFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        // 8. Decode JSON Response
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            let proposals = try decoder.decode([Proposal].self, from: data)
            print("Successfully fetched \(proposals.count) proposals.")
            return proposals
        } catch {
            print("Error: Failed to decode JSON response - \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                 print("Raw JSON Response: \(jsonString)")
            }
            throw SupabaseError.jsonDecodingError(error)
        }
    }
}
