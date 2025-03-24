import Foundation

extension FlightBooking {
    // Store flight booking details in Mem0 with temporal context
    func storeInMemory(service: MemoryService = MemoryService(), completion: @escaping (Result<Bool, Error>) -> Void) {
        // Determine if flight is in the past, current, or future
        let now = Date()
        let timeContext: String
        
        if flight.arrivalDate < now {
            timeContext = "PAST FLIGHT: This flight has already completed."
        } else if flight.departureDate > now {
            timeContext = "UPCOMING FLIGHT: This flight is scheduled for the future."
        } else {
            timeContext = "CURRENT FLIGHT: This flight is currently in progress."
        }
        
        // Format flight booking information in a readable, searchable way
        var content = """
        \(timeContext)
        
        Flight booking: \(flight.number) 
        From: \(flight.departureName) (\(flight.departureCode)) 
        To: \(flight.arrivalName) (\(flight.arrivalCode))
        Departure: \(flight.departureDate.formatted(date: .long, time: .shortened))
        Arrival: \(flight.arrivalDate.formatted(date: .long, time: .shortened))
        """
        
        // Add different context based on whether it's part of a trip
        if isPartOfTrip {
            content += "\nThis flight is part of your \(tripId ?? "existing") trip."
        } else {
            content += "\nThis is a standalone flight booking (not part of a trip)."
        }
        
        service.addMemory(content: content, userId: userId, completion: completion)
    }
} 