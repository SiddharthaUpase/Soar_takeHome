import Foundation
import FirebaseFirestore

struct FlightBooking: Identifiable, Codable, Equatable {
    var id: String
    let flight: Flight
    let userId: String
    let isPartOfTrip: Bool
    let tripId: String?
    
    init(id: String = UUID().uuidString, 
         flight: Flight, 
         userId: String,
         isPartOfTrip: Bool = false, 
         tripId: String? = nil) {
        self.id = id
        self.flight = flight
        self.userId = userId
        self.isPartOfTrip = isPartOfTrip
        self.tripId = tripId
    }
    
    // Convert to Firestore data
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "flight": flight.toDictionary(),
            "userId": userId,
            "isPartOfTrip": isPartOfTrip
        ]
        
        if let tripId = tripId {
            dict["tripId"] = tripId
        }
        
        return dict
    }
    
    static func == (lhs: FlightBooking, rhs: FlightBooking) -> Bool {
        return lhs.id == rhs.id
    }
} 