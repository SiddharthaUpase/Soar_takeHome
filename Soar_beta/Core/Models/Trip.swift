import Foundation
import FirebaseFirestore

struct Trip: Identifiable, Codable {
    var id: String
    let name: String
    let flights: [Flight]
    let accommodations: [Accommodation]
    let startDate: Date
    let endDate: Date
    let userId: String
    
    // For creating a new trip
    init(id: String = UUID().uuidString, 
         name: String, 
         flights: [Flight], 
         accommodations: [Accommodation], 
         startDate: Date, 
         endDate: Date,
         userId: String) {
        self.id = id
        self.name = name
        self.flights = flights
        self.accommodations = accommodations
        self.startDate = startDate
        self.endDate = endDate
        self.userId = userId
    }
    
    // Convert to Firestore data
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "flights": flights.map { $0.toDictionary() },
            "accommodations": accommodations.map { $0.toDictionary() },
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "userId": userId
        ]
    }
} 