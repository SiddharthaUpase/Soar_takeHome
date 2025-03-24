import Foundation

extension Trip {
    // Store trip details in Mem0
    func storeInMemory(service: MemoryService = MemoryService(), completion: @escaping (Result<Bool, Error>) -> Void) {
        let content = """
        Trip to \(name) from \(startDate.formatted(date: .long, time: .omitted)) to \(endDate.formatted(date: .long, time: .omitted)).
        Total flights: \(flights.count)
        Total accommodations: \(accommodations.count)
        """
        
        service.addMemory(content: content, userId: userId, completion: completion)
    }
    
    // Store more detailed trip information
    func storeDetailedInMemory(service: MemoryService = MemoryService(), completion: @escaping (Result<Bool, Error>) -> Void) {
        // Determine if trip is in the past, current, or future
        let now = Date()
        let timeContext: String
        
        if endDate < now {
            timeContext = "PAST TRIP: This trip has already concluded as of \(endDate.formatted(date: .long, time: .omitted))."
        } else if startDate > now {
            timeContext = "UPCOMING TRIP: This trip is scheduled for the future, starting on \(startDate.formatted(date: .long, time: .omitted))."
        } else {
            timeContext = "CURRENT TRIP: This trip is currently in progress (from \(startDate.formatted(date: .long, time: .omitted)) to \(endDate.formatted(date: .long, time: .omitted)))."
        }
        
        var flightDetails = "Flights:"
        for flight in flights {
            flightDetails += """
            
            • Flight \(flight.number): From \(flight.departureName) (\(flight.departureCode)) to \(flight.arrivalName) (\(flight.arrivalCode))
              Departure: \(flight.departureDate.formatted(date: .long, time: .shortened))
              Arrival: \(flight.arrivalDate.formatted(date: .long, time: .shortened))
            """
        }
        
        var accommodationDetails = "Accommodations:"
        for accommodation in accommodations {
            accommodationDetails += """
            
            • Stay at \(accommodation.name) (\(accommodation.agent))
              Address: \(accommodation.address)
              Check-in: \(accommodation.checkInDate.formatted(date: .long, time: .omitted))
              Check-out: \(accommodation.checkOutDate.formatted(date: .long, time: .omitted))
            """
        }
        
        let content = """
        \(timeContext)
        
        Trip to \(name) from \(startDate.formatted(date: .long, time: .omitted)) to \(endDate.formatted(date: .long, time: .omitted)).
        
        \(flightDetails)
        
        \(accommodationDetails)
        """
        
        service.addMemory(content: content, userId: userId, completion: completion)
    }
} 