import Foundation

extension Flight {
    // Store flight details in Mem0
    func storeInMemory(userId: String, service: MemoryService = MemoryService(), completion: @escaping (Result<Bool, Error>) -> Void) {
        let content = """
        Flight \(number): From \(departureName) (\(departureCode)) to \(arrivalName) (\(arrivalCode))
        Departure: \(departureDate.formatted(date: .long, time: .shortened))
        Arrival: \(arrivalDate.formatted(date: .long, time: .shortened))
        """
        
        service.addMemory(content: content, userId: userId, completion: completion)
    }
} 