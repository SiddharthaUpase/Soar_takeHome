import Foundation
import SwiftUI
import Combine

class AddTripViewModel: ObservableObject {
    // Trip basic info
    @Published var tripName = ""
    @Published var startDate = Date()
    @Published var endDate = Date().addingTimeInterval(86400 * 7) // One week later
    
    // Flights
    @Published var flights: [FlightFormModel] = [FlightFormModel()]
    
    // Accommodations
    @Published var accommodations: [AccommodationFormModel] = [AccommodationFormModel()]
    
    // Validation
    var isFormValid: Bool {
        !tripName.isEmpty && 
        startDate < endDate && 
        flights.allSatisfy({ $0.isValid }) &&
        accommodations.allSatisfy({ $0.isValid })
    }
    
    // Methods to add/remove flights and accommodations
    func addFlight() {
        flights.append(FlightFormModel())
    }
    
    func removeFlight(at index: Int) {
        if flights.count > 1 {
            flights.remove(at: index)
        }
    }
    
    func addAccommodation() {
        accommodations.append(AccommodationFormModel())
    }
    
    func removeAccommodation(at index: Int) {
        if accommodations.count > 1 {
            accommodations.remove(at: index)
        }
    }
    
    // Dropdown options for airports and locations
    let airportOptions = [
        Airport(code: "JFK", name: "John F. Kennedy International", city: "New York"),
        Airport(code: "LHR", name: "Heathrow Airport", city: "London"),
        Airport(code: "CDG", name: "Charles de Gaulle Airport", city: "Paris"),
        Airport(code: "HND", name: "Haneda Airport", city: "Tokyo"),
        Airport(code: "DXB", name: "Dubai International", city: "Dubai"),
        Airport(code: "SIN", name: "Changi Airport", city: "Singapore"),
        Airport(code: "SFO", name: "San Francisco International", city: "San Francisco"),
        Airport(code: "LAX", name: "Los Angeles International", city: "Los Angeles"),
        Airport(code: "FCO", name: "Leonardo da Vinci International", city: "Rome"),
        Airport(code: "BCN", name: "Barcelona–El Prat", city: "Barcelona"),
        Airport(code: "BER", name: "Berlin Brandenburg", city: "Berlin"),
        Airport(code: "DEL", name: "Indira Gandhi International", city: "Delhi"),
        Airport(code: "BOM", name: "Chhatrapati Shivaji Maharaj", city: "Mumbai"),
        Airport(code: "SYD", name: "Sydney Airport", city: "Sydney"),
        Airport(code: "MEL", name: "Melbourne Airport", city: "Melbourne")
    ]
    
    // Method to build Trip from form data
    func buildTrip(userId: String) -> Trip {
        let tripFlights = flights.map { formModel in
            return Flight(
                id: UUID().uuidString,
                number: formModel.flightNumber,
                airline: formModel.airline,
                departureName: formModel.departureAirport.name,
                departureCode: formModel.departureAirport.code,
                arrivalName: formModel.arrivalAirport.name,
                arrivalCode: formModel.arrivalAirport.code,
                departureDate: formModel.departureDate,
                arrivalDate: formModel.arrivalDate
            )
        }
        
        let tripAccommodations = accommodations.map { formModel in
            return Accommodation(
                id: UUID().uuidString,
                agent: formModel.agent,
                name: formModel.name,
                address: formModel.address,
                checkInDate: formModel.checkInDate,
                checkOutDate: formModel.checkOutDate
            )
        }
        
        return Trip(
            name: tripName,
            flights: tripFlights,
            accommodations: tripAccommodations,
            startDate: startDate,
            endDate: endDate,
            userId: userId
        )
    }
}

// Helper form models
struct FlightFormModel: Identifiable {
    var id = UUID()
    var airline = ""
    var flightNumber = ""
    var departureAirport: Airport = Airport(code: "", name: "", city: "")
    var departureDate = Date()
    var arrivalAirport: Airport = Airport(code: "", name: "", city: "")
    var arrivalDate = Date().addingTimeInterval(3600 * 3) // 3 hours later
    
    var isValid: Bool {
        !flightNumber.isEmpty && 
        !departureAirport.code.isEmpty && 
        !arrivalAirport.code.isEmpty &&
        departureDate < arrivalDate
    }
}

struct AccommodationFormModel: Identifiable {
    var id = UUID()
    var name = ""
    var address = ""
    var agent = ""
    var checkInDate = Date()
    var checkOutDate = Date().addingTimeInterval(86400 * 5) // 5 days later
    
    var isValid: Bool {
        !name.isEmpty && 
        !address.isEmpty && 
        checkInDate < checkOutDate
    }
}

struct Airport: Identifiable, Hashable {
    var id: String { code }
    var code: String
    var name: String
    var city: String
} 