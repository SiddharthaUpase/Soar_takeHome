import Foundation
import FirebaseFirestore

struct Flight: Identifiable, Codable, Equatable {
    var id: String
    let number: String
    let airline: String?
    let departureName: String
    let departureCode: String
    let arrivalName: String
    let arrivalCode: String
    let departureDate: Date
    let arrivalDate: Date
    
    init(id: String = UUID().uuidString,
         number: String,
         airline: String? = nil,
         departureName: String,
         departureCode: String,
         arrivalName: String,
         arrivalCode: String,
         departureDate: Date,
         arrivalDate: Date) {
        self.id = id
        self.number = number
        self.airline = airline
        self.departureName = departureName
        self.departureCode = departureCode
        self.arrivalName = arrivalName
        self.arrivalCode = arrivalCode
        self.departureDate = departureDate
        self.arrivalDate = arrivalDate
    }
    
    // Convert to Firestore data
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "number": number,
            "departureName": departureName,
            "departureCode": departureCode,
            "arrivalName": arrivalName,
            "arrivalCode": arrivalCode,
            "departureDate": Timestamp(date: departureDate),
            "arrivalDate": Timestamp(date: arrivalDate)
        ]
        
        // Only add airline if it's not nil
        if let airline = airline {
            dict["airline"] = airline
        }
        
        return dict
    }
    
    static func == (lhs: Flight, rhs: Flight) -> Bool {
        return lhs.id == rhs.id
    }
} 