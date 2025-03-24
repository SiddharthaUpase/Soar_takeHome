import Foundation
import FirebaseFirestore

class MemorySyncService {
    private let memoryService: MemoryService
    private let db = Firestore.firestore()
    
    init(memoryService: MemoryService = MemoryService()) {
        self.memoryService = memoryService
    }
    
    // Sync all user trips to memory
    func syncUserTripsToMemory(userId: String, trips: [Trip], completion: @escaping (Int, Int) -> Void) {
        // First check which trips have already been synced
        getSyncedTripIds(userId: userId) { [weak self] syncedTripIds in
            guard let self = self else { return }
            
            // Filter out trips that have already been synced
            let tripsToSync = trips.filter { !syncedTripIds.contains($0.id) }
            
            if tripsToSync.isEmpty {
                // No new trips to sync
                completion(0, 0)
                return
            }
            
            var successCount = 0
            var failureCount = 0
            let totalToSync = tripsToSync.count
            let dispatchGroup = DispatchGroup()
            
            for trip in tripsToSync {
                dispatchGroup.enter()
                
                trip.storeDetailedInMemory { result in
                    switch result {
                    case .success:
                        // Mark trip as synced in Firestore
                        self.markTripAsSynced(userId: userId, tripId: trip.id) { success in
                            if success {
                                successCount += 1
                            } else {
                                failureCount += 1
                            }
                            dispatchGroup.leave()
                        }
                    case .failure:
                        failureCount += 1
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(successCount, failureCount)
            }
        }
    }
    
    // Sync a single trip (useful for when a new trip is created or updated)
    func syncTrip(userId: String, trip: Trip, completion: @escaping (Bool) -> Void) {
        // Check if this trip has already been synced
        getSyncedTripIds(userId: userId) { [weak self] syncedTripIds in
            guard let self = self else {
                completion(false)
                return
            }
            
            // If trip is already synced and this is an update, we should remove it first
            if syncedTripIds.contains(trip.id) {
                // For simplicity in this MVP, we'll just overwrite the trip in memory
                // In a production app, you might want to use the update method instead
            }
            
            // Store the trip in memory
            trip.storeDetailedInMemory { result in
                switch result {
                case .success:
                    // Mark the trip as synced
                    self.markTripAsSynced(userId: userId, tripId: trip.id) { success in
                        completion(success)
                    }
                case .failure:
                    completion(false)
                }
            }
        }
    }
    
    // Get list of trip IDs that have already been synced to memory
    private func getSyncedTripIds(userId: String, completion: @escaping ([String]) -> Void) {
        db.collection("memorySyncs")
            .document(userId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error getting synced trip ids: \(error)")
                    completion([])
                    return
                }
                
                guard let data = snapshot?.data(),
                      let syncedTrips = data["syncedTripIds"] as? [String] else {
                    completion([])
                    return
                }
                
                completion(syncedTrips)
            }
    }
    
    // Mark a trip as synced in Firestore
    private func markTripAsSynced(userId: String, tripId: String, completion: @escaping (Bool) -> Void) {
        // First get the current list of synced trip IDs
        getSyncedTripIds(userId: userId) { [weak self] syncedTripIds in
            guard let self = self else {
                completion(false)
                return
            }
            
            // Add this trip ID if it's not already there
            var updatedSyncedTripIds = syncedTripIds
            if !updatedSyncedTripIds.contains(tripId) {
                updatedSyncedTripIds.append(tripId)
            }
            
            // Update the document
            self.db.collection("memorySyncs")
                .document(userId)
                .setData(["syncedTripIds": updatedSyncedTripIds], merge: true) { error in
                    if let error = error {
                        print("Error marking trip as synced: \(error)")
                        completion(false)
                        return
                    }
                    
                    completion(true)
                }
        }
    }
    
    // Track synced flight bookings
    private func getSyncedFlightBookingIds(userId: String, completion: @escaping ([String]) -> Void) {
        db.collection("memorySyncs")
            .document(userId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error getting synced flight booking ids: \(error)")
                    completion([])
                    return
                }
                
                guard let data = snapshot?.data(),
                      let syncedFlightBookings = data["syncedFlightBookingIds"] as? [String] else {
                    completion([])
                    return
                }
                
                completion(syncedFlightBookings)
            }
    }
    
    // Mark flight booking as synced
    private func markFlightBookingAsSynced(userId: String, flightBookingId: String, completion: @escaping (Bool) -> Void) {
        getSyncedFlightBookingIds(userId: userId) { [weak self] syncedIds in
            guard let self = self else {
                completion(false)
                return
            }
            
            var updatedSyncedIds = syncedIds
            if !updatedSyncedIds.contains(flightBookingId) {
                updatedSyncedIds.append(flightBookingId)
            }
            
            self.db.collection("memorySyncs")
                .document(userId)
                .setData(["syncedFlightBookingIds": updatedSyncedIds], merge: true) { error in
                    if let error = error {
                        print("Error marking flight booking as synced: \(error)")
                        completion(false)
                        return
                    }
                    
                    completion(true)
                }
        }
    }
    
    // Sync user flight bookings to memory
    func syncUserFlightBookingsToMemory(userId: String, flightBookings: [FlightBooking], completion: @escaping (Int, Int) -> Void) {
        // Get already synced flight booking IDs
        getSyncedFlightBookingIds(userId: userId) { [weak self] syncedFlightBookingIds in
            guard let self = self else { return }
            
            // Filter out bookings that have already been synced
            let bookingsToSync = flightBookings.filter { !syncedFlightBookingIds.contains($0.id) }
            
            if bookingsToSync.isEmpty {
                completion(0, 0)
                return
            }
            
            var successCount = 0
            var failureCount = 0
            let dispatchGroup = DispatchGroup()
            
            for booking in bookingsToSync {
                dispatchGroup.enter()
                
                booking.storeInMemory { [weak self] result in
                    guard let self = self else {
                        dispatchGroup.leave()
                        return
                    }
                    
                    switch result {
                    case .success:
                        self.markFlightBookingAsSynced(userId: userId, flightBookingId: booking.id) { success in
                            if success {
                                successCount += 1
                            } else {
                                failureCount += 1
                            }
                            dispatchGroup.leave()
                        }
                    case .failure:
                        failureCount += 1
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(successCount, failureCount)
            }
        }
    }
} 