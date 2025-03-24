import Foundation
import Firebase
import FirebaseFirestore

class TravelDataService {
    private let db = Firestore.firestore()
    
    // Check if user already has travel data in Firestore
    func checkUserHasData(userId: String, completion: @escaping (Bool) -> Void) {
        let dispatchGroup = DispatchGroup()
        var hasTrips = false
        var hasFlightBookings = false
        
        dispatchGroup.enter()
        db.collection("trips")
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let snapshot = snapshot, !snapshot.documents.isEmpty {
                    hasTrips = true
                }
                dispatchGroup.leave()
            }
        
        dispatchGroup.enter()
        db.collection("flightBookings")
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let snapshot = snapshot, !snapshot.documents.isEmpty {
                    hasFlightBookings = true
                }
                dispatchGroup.leave()
            }
        
        dispatchGroup.notify(queue: .main) {
            completion(hasTrips || hasFlightBookings)
        }
    }
    
    // Parse dummy data and store in Firestore (hard-coded for now)
    func parseDummyData(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // 1. Parse JSON
        guard let url = Bundle.main.url(forResource: "dummy_data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dummyData = try? JSONDecoder().decode(DummyData.self, from: data) else {
            completion(.failure(NSError(domain: "TravelDataService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load or parse dummy data"])))
            return
        }
        
        // 2. Process flights
        let flights = dummyData.travelFlights.map { flightData -> Flight in
            // Create Flight object
            let departureDate = ISO8601DateFormatter().date(from: flightData.departureDate) ?? Date()
            let arrivalDate = ISO8601DateFormatter().date(from: flightData.arrivalDate) ?? Date()
            
            return Flight(
                id: UUID().uuidString,
                number: flightData.number,
                departureName: flightData.departureName,
                departureCode: flightData.departureCode,
                arrivalName: flightData.arrivalName,
                arrivalCode: flightData.arrivalCode,
                departureDate: departureDate,
                arrivalDate: arrivalDate
            )
        }
        
        // 3. Process accommodations
        let accommodations = dummyData.travelAccomodations.map { accommodationData -> Accommodation in
            // Create Accommodation object
            let checkInDate = ISO8601DateFormatter().date(from: accommodationData.checkInDate) ?? Date()
            let checkOutDate = ISO8601DateFormatter().date(from: accommodationData.checkOutDate) ?? Date()
            
            return Accommodation(
                id: UUID().uuidString,
                agent: accommodationData.agent,
                name: accommodationData.name,
                address: accommodationData.address,
                checkInDate: checkInDate,
                checkOutDate: checkOutDate
            )
        }
        
        // 4. Detect trips (hard-coded for Europe trip)
        let (trips, singleFlights) = detectTrips(flights: flights, accommodations: accommodations, userId: userId)
        
        // 5. Store in Firestore
        let dispatchGroup = DispatchGroup()
        var storeError: Error?
        
        // Store trips
        for trip in trips {
            dispatchGroup.enter()
            db.collection("trips").document(trip.id).setData(trip.toDictionary()) { error in
                if let error = error {
                    storeError = error
                }
                dispatchGroup.leave()
            }
        }
        
        // Store flight bookings
        for booking in singleFlights {
            dispatchGroup.enter()
            db.collection("flightBookings").document(booking.id).setData(booking.toDictionary()) { error in
                if let error = error {
                    storeError = error
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if let error = storeError {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Trip Detection Logic (Hardcoded)
    
    private func detectTrips(flights: [Flight], accommodations: [Accommodation], userId: String) -> (trips: [Trip], singleFlights: [FlightBooking]) {
        var trips: [Trip] = []
        var singleFlights: [FlightBooking] = []
        
        // Hardcoded Europe trip detection
        // Define the airports for the Europe trip
        let europeAirports = ["LHR", "ATH", "FRA", "DFW", "SFO"]
        let europeFlightNumbers = ["A3 603", "LH 1279", "BA 901", "AA 79", "AA 2997"]
        
        // Filter flights for Europe trip (Feb 22-27, 2025)
        let dateFormatter = ISO8601DateFormatter()
        let startDate = dateFormatter.date(from: "2025-02-22T00:00:00+00:00") ?? Date()
        let endDate = dateFormatter.date(from: "2025-02-28T00:00:00+00:00") ?? Date()
        
        let europeFlights = flights.filter { flight in
            europeFlightNumbers.contains(flight.number) &&
            flight.departureDate >= startDate &&
            flight.departureDate <= endDate
        }.sorted(by: { $0.departureDate < $1.departureDate })
        
        // Create Europe trip
        if !europeFlights.isEmpty {
            let europeTrip = Trip(
                id: UUID().uuidString,
                name: "Europe Tour February 2025",
                flights: europeFlights,
                accommodations: accommodations, // All accommodations are part of this trip
                startDate: europeFlights.first?.departureDate ?? startDate,
                endDate: europeFlights.last?.arrivalDate ?? endDate,
                userId: userId
            )
            
            trips.append(europeTrip)
        }
        
        // Process remaining flights as standalone bookings
        let europeFlightIds = Set(europeFlights.map { $0.id })
        let remainingFlights = flights.filter { !europeFlightIds.contains($0.id) }
        
        for flight in remainingFlights {
            let booking = FlightBooking(
                id: UUID().uuidString,
                flight: flight,
                userId: userId,
                isPartOfTrip: false
            )
            singleFlights.append(booking)
        }
        
        return (trips, singleFlights)
    }
}

// MARK: - Dummy Data Models

struct DummyData: Codable {
    let merchantId: String
    let receiptId: String
    let storeName: String
    let travelFlights: [DummyFlight]
    let travelAccomodations: [DummyAccommodation]
    
    enum CodingKeys: String, CodingKey {
        case merchantId = "MerchantId"
        case receiptId
        case storeName
        case travelFlights
        case travelAccomodations
    }
}

struct DummyFlight: Codable {
    let number: String
    let departureName: String
    let departureCode: String
    let arrivalName: String
    let arrivalCode: String
    let departureDate: String
    let arrivalDate: String
}

struct DummyAccommodation: Codable {
    let agent: String
    let name: String
    let address: String
    let checkInDate: String
    let checkOutDate: String
} 