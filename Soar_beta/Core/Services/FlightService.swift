import Foundation
import FirebaseFirestore

class FlightService {
    private let db = Firestore.firestore()
    
    func saveFlightBooking(_ flightBooking: FlightBooking, completion: @escaping (Result<Void, Error>) -> Void) {
        let bookingData = flightBooking.toDictionary()
        
        db.collection("flightBookings").document(flightBooking.id).setData(bookingData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchFlightBookings(for userId: String, completion: @escaping (Result<[FlightBooking], Error>) -> Void) {
        db.collection("flightBookings")
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
                
                var bookings: [FlightBooking] = []
                
                for document in documents {
                    let data = document.data()
                    
                    if let id = data["id"] as? String,
                       let userId = data["userId"] as? String,
                       let isPartOfTrip = data["isPartOfTrip"] as? Bool,
                       let flightData = data["flight"] as? [String: Any],
                       let number = flightData["number"] as? String,
                       let departureName = flightData["departureName"] as? String,
                       let departureCode = flightData["departureCode"] as? String,
                       let arrivalName = flightData["arrivalName"] as? String,
                       let arrivalCode = flightData["arrivalCode"] as? String,
                       let departureTimestamp = flightData["departureDate"] as? Timestamp,
                       let arrivalTimestamp = flightData["arrivalDate"] as? Timestamp {
                        
                        let airline = flightData["airline"] as? String
                        let tripId = data["tripId"] as? String
                        
                        let flight = Flight(
                            number: number,
                            airline: airline,
                            departureName: departureName,
                            departureCode: departureCode,
                            arrivalName: arrivalName,
                            arrivalCode: arrivalCode,
                            departureDate: departureTimestamp.dateValue(),
                            arrivalDate: arrivalTimestamp.dateValue()
                        )
                        
                        let booking = FlightBooking(
                            id: id,
                            flight: flight,
                            userId: userId,
                            isPartOfTrip: isPartOfTrip,
                            tripId: tripId
                        )
                        
                        bookings.append(booking)
                    }
                }
                
                completion(.success(bookings))
            }
    }
    
    func deleteFlightBooking(_ bookingId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("flightBookings").document(bookingId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
} 