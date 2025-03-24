import Foundation
import FirebaseFirestore

class TripService {
    private let db = Firestore.firestore()
    
    func saveTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void) {
        let tripData = trip.toDictionary()
        
        db.collection("trips").document(trip.id).setData(tripData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchTrips(for userId: String, completion: @escaping (Result<[Trip], Error>) -> Void) {
        db.collection("trips")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                var trips: [Trip] = []
                
                for document in documents {
                    let data = document.data()
                    
                    // Parse flight data
                    var flights: [Flight] = []
                    if let flightData = data["flights"] as? [[String: Any]] {
                        for flight in flightData {
                            if let id = flight["id"] as? String,
                               let number = flight["number"] as? String,
                               let departureName = flight["departureName"] as? String,
                               let departureCode = flight["departureCode"] as? String,
                               let arrivalName = flight["arrivalName"] as? String,
                               let arrivalCode = flight["arrivalCode"] as? String,
                               let departureTimestamp = flight["departureDate"] as? Timestamp,
                               let arrivalTimestamp = flight["arrivalDate"] as? Timestamp {
                                
                                // Get airline as an optional string
                                let airline = flight["airline"] as? String
                                
                                let flight = Flight(
                                    id: id,
                                    number: number,
                                    airline: airline, // Pass as optional
                                    departureName: departureName,
                                    departureCode: departureCode,
                                    arrivalName: arrivalName,
                                    arrivalCode: arrivalCode,
                                    departureDate: departureTimestamp.dateValue(),
                                    arrivalDate: arrivalTimestamp.dateValue()
                                )
                                flights.append(flight)
                            }
                        }
                    }
                    
                    // Parse accommodation data
                    var accommodations: [Accommodation] = []
                    if let accommodationData = data["accommodations"] as? [[String: Any]] {
                        for accommodation in accommodationData {
                            if let id = accommodation["id"] as? String,
                               let name = accommodation["name"] as? String,
                               let address = accommodation["address"] as? String,
                               let agent = accommodation["agent"] as? String,
                               let checkInTimestamp = accommodation["checkInDate"] as? Timestamp,
                               let checkOutTimestamp = accommodation["checkOutDate"] as? Timestamp {
                                
                                let accommodation = Accommodation(
                                    id: id,
                                    agent: agent,
                                    name: name,
                                    address: address,
                                    checkInDate: checkInTimestamp.dateValue(),
                                    checkOutDate: checkOutTimestamp.dateValue()
                                )
                                accommodations.append(accommodation)
                            }
                        }
                    }
                    
                    // Create Trip object
                    if let id = data["id"] as? String,
                       let name = data["name"] as? String,
                       let startTimestamp = data["startDate"] as? Timestamp,
                       let endTimestamp = data["endDate"] as? Timestamp,
                       let userId = data["userId"] as? String {
                        
                        let trip = Trip(
                            id: id,
                            name: name,
                            flights: flights,
                            accommodations: accommodations,
                            startDate: startTimestamp.dateValue(),
                            endDate: endTimestamp.dateValue(),
                            userId: userId
                        )
                        trips.append(trip)
                    }
                }
                
                completion(.success(trips))
            }
    }
    
    func deleteTrip(_ tripId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("trips").document(tripId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
} 