import SwiftUI

struct MyPickupsView: View {
    @State private var proposals: [Proposal] = []
    @State private var errorMessage: String? = nil

    private let proposalService = ProposalService(
        baseURL: SupabaseConfig.baseURL,
        apiKey: SupabaseConfig.apiKey,
        authToken: SupabaseConfig.authToken
    )

    var body: some View {
        VStack {
            if let error = errorMessage {
                Text("Error: \(error)").foregroundColor(.red)
            }
            List(proposals, id: \.id) { proposal in
                VStack(alignment: .leading) {
                    Text(proposal.location)
                    Text("Starts: \(proposal.startTime)")
                    Text("Ends: \(proposal.endTime)")
                }
            }
        }
        .onAppear {
            Task {
                do {
                    proposals = try await proposalService.fetchProposals()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .navigationTitle("My Pickups")
    }
}