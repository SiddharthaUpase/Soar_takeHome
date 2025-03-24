import Foundation

// This is a demonstration file showing how to test the memory sync functionality
// You can use this for reference when implementing the actual app logic

class MemorySyncTest {
    private let memorySyncService = MemorySyncService()
    private let memoryService = MemoryService()
    
    // Test syncing all trips for a user after login
    func testSyncAllTrips(userId: String, trips: [Trip]) {
        print("Starting sync of \(trips.count) trips for user \(userId)")
        
        memorySyncService.syncUserTripsToMemory(userId: userId, trips: trips) { successCount, failureCount in
            print("Sync completed:")
            print("- Successfully synced: \(successCount)")
            print("- Failed to sync: \(failureCount)")
        }
    }
    
    // Test syncing a single trip (e.g., after creating or updating a trip)
    func testSyncSingleTrip(userId: String, trip: Trip) {
        print("Syncing trip \(trip.id) (\(trip.name)) for user \(userId)")
        
        memorySyncService.syncTrip(userId: userId, trip: trip) { success in
            if success {
                print("Successfully synced trip")
            } else {
                print("Failed to sync trip")
            }
        }
    }
    
    // Test retrieving memory information for a specific query
    func testQueryMemory(userId: String, query: String) {
        print("Querying memory for user \(userId) with query: \"\(query)\"")
        
        memoryService.searchMemories(query: query, userId: userId) { result in
            switch result {
            case .success(let memories):
                print("Found \(memories.count) relevant memories:")
                for (index, memory) in memories.enumerated() {
                    print("\(index + 1). \(memory)")
                }
                
                if memories.isEmpty {
                    print("No relevant memories found")
                }
            case .failure(let error):
                print("Error querying memory: \(error)")
            }
        }
    }
    
    // Example of how to use these test methods in your app
    func runTest(userId: String, trips: [Trip]) {
        // 1. Sync all trips
        testSyncAllTrips(userId: userId, trips: trips)
        
        // 2. Query memory for trips to a specific destination
        if let trip = trips.first {
            testQueryMemory(userId: userId, query: "Tell me about my trip to \(trip.name)")
        }
        
        // 3. Query memory for flights
        testQueryMemory(userId: userId, query: "What flights do I have coming up?")
    }
} 