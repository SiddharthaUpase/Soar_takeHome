import Foundation
import FirebaseFirestore

struct Accommodation: Identifiable, Codable {
    var id: String
    let agent: String
    let name: String
    let address: String
    let checkInDate: Date
    let checkOutDate: Date
    
    init(id: String = UUID().uuidString,
         agent: String,
         name: String,
         address: String,
         checkInDate: Date,
         checkOutDate: Date) {
        self.id = id
        self.agent = agent
        self.name = name
        self.address = address
        self.checkInDate = checkInDate
        self.checkOutDate = checkOutDate
    }
    
    // Convert to Firestore data
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "agent": agent,
            "name": name,
            "address": address,
            "checkInDate": Timestamp(date: checkInDate),
            "checkOutDate": Timestamp(date: checkOutDate)
        ]
    }
} 