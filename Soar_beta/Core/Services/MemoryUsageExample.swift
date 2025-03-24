import Foundation

// This is an example file demonstrating how to use the Memory service
// You would integrate these calls into your existing app flow

class MemoryIntegrationExample {
    
    // Example: Store trip information when a new trip is created
    func storeNewTripInMemory(trip: Trip) {
        trip.storeDetailedInMemory { result in
            switch result {
            case .success:
                print("Successfully stored trip details in memory")
            case .failure(let error):
                print("Failed to store trip details: \(error)")
            }
        }
    }
    
    // Example: Store a flight when booked
    func storeFlightInMemory(flight: Flight, userId: String) {
        flight.storeInMemory(userId: userId) { result in
            switch result {
            case .success:
                print("Successfully stored flight details in memory")
            case .failure(let error):
                print("Failed to store flight details: \(error)")
            }
        }
    }
    
    // Example: How to integrate with a chat interface
    func handleChatMessage(message: String, userId: String, completion: @escaping (String) -> Void) {
        let chatHelper = ChatMemoryHelper()
        chatHelper.processUserMessage(message, userId: userId) { response in
            completion(response)
        }
    }
    
    // Example: Integration points in your app
    
    // 1. When creating a new trip
    func onTripCreated(_ trip: Trip) {
        storeNewTripInMemory(trip: trip)
    }
    
    // 2. When updating a trip with new flights or accommodations
    func onTripUpdated(_ trip: Trip) {
        storeNewTripInMemory(trip: trip)
    }
    
    // 3. In chat view when user sends a message
    func onChatMessageSent(message: String, userId: String, updateUI: @escaping (String) -> Void) {
        handleChatMessage(message: message, userId: userId) { response in
            // Update your chat UI with the response
            updateUI(response)
        }
    }
} 