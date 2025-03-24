import SwiftUI

struct AddFlightView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var airline = ""
    @State private var flightNumber = ""
    @State private var departureAirport: Airport?
    @State private var arrivalAirport: Airport?
    @State private var departureDate = Date()
    @State private var arrivalDate = Date().addingTimeInterval(3600 * 3) // 3 hours later
    
    @State private var showingDepartureAirports = false
    @State private var showingArrivalAirports = false
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertTitle = "Error"
    @State private var alertMessage = ""
    
    private let airportOptions = [
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
    
    private var isFormValid: Bool {
        !flightNumber.isEmpty && 
        departureAirport != nil && 
        arrivalAirport != nil &&
        departureDate < arrivalDate
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Flight information group
                Section(header: Text("Flight Information")) {
                    TextField("Airline (e.g. United, Delta)", text: $airline)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            Text("Optional")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .background(Color(.systemBackground))
                                .opacity(airline.isEmpty ? 1 : 0),
                            alignment: .trailing
                        )
                        .padding(.trailing, 8)
                    
                    TextField("Flight Number (e.g. UA123)", text: $flightNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.namePhonePad)
                }
                
                // Departure information
                Section(header: Text("Departure")) {
                    Button(action: { showingDepartureAirports = true }) {
                        HStack {
                            Text("From:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(departureAirport == nil ? "Select Airport" : "\(departureAirport!.city) (\(departureAirport!.code))")
                                .foregroundColor(departureAirport == nil ? .secondary : .primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .sheet(isPresented: $showingDepartureAirports) {
                        AirportSelectionView(selectedAirport: $departureAirport, airports: airportOptions)
                    }
                    
                    DatePicker("Departure Date & Time", selection: $departureDate)
                        .onChange(of: departureDate) { newValue in
                            if newValue >= arrivalDate {
                                arrivalDate = newValue.addingTimeInterval(3600 * 3) // 3 hours later
                            }
                        }
                }
                
                // Arrival information
                Section(header: Text("Arrival")) {
                    Button(action: { showingArrivalAirports = true }) {
                        HStack {
                            Text("To:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(arrivalAirport == nil ? "Select Airport" : "\(arrivalAirport!.city) (\(arrivalAirport!.code))")
                                .foregroundColor(arrivalAirport == nil ? .secondary : .primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .sheet(isPresented: $showingArrivalAirports) {
                        AirportSelectionView(selectedAirport: $arrivalAirport, airports: airportOptions)
                    }
                    
                    DatePicker("Arrival Date & Time", selection: $arrivalDate)
                }
                
                // Save button
                Section {
                    Button(action: saveFlight) {
                        HStack {
                            Spacer()
                            Text("Save Flight")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isSaving)
                    .listRowBackground(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Flight")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay(
                ZStack {
                    if isSaving {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            Text("Saving flight...")
                                .foregroundColor(.white)
                                .padding()
                        }
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                        .shadow(radius: 10)
                    }
                }
            )
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func saveFlight() {
        guard let userId = authViewModel.currentUser?.id else {
            alertTitle = "Error"
            alertMessage = "You must be logged in to save a flight."
            showingAlert = true
            return
        }
        
        guard let departure = departureAirport, let arrival = arrivalAirport else {
            alertTitle = "Error"
            alertMessage = "Please select both departure and arrival airports."
            showingAlert = true
            return
        }
        
        isSaving = true
        
        // Create Flight object
        let flight = Flight(
            number: flightNumber,
            airline: airline.isEmpty ? nil : airline,
            departureName: departure.name,
            departureCode: departure.code,
            arrivalName: arrival.name,
            arrivalCode: arrival.code,
            departureDate: departureDate,
            arrivalDate: arrivalDate
        )
        
        // Create FlightBooking
        let flightBooking = FlightBooking(
            id: UUID().uuidString,
            flight: flight,
            userId: userId,
            isPartOfTrip: false
        )
        
        // Save to database
        let flightService = FlightService()
        flightService.saveFlightBooking(flightBooking) { result in
            switch result {
            case .success:
                // Store in Memory Service
                storeFlightInMemory(flight: flight, userId: userId) { memoryResult in
                    DispatchQueue.main.async {
                        isSaving = false
                        dismiss()
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    isSaving = false
                    alertTitle = "Error"
                    alertMessage = "Error saving flight: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func storeFlightInMemory(flight: Flight, userId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let memoryService = MemoryService()
        
        // Format flight details for memory
        let now = Date()
        let timeContext: String
        
        if flight.arrivalDate < now {
            timeContext = "PAST FLIGHT"
        } else if flight.departureDate > now {
            timeContext = "UPCOMING FLIGHT"
        } else {
            timeContext = "CURRENT FLIGHT"
        }
        
        let airlineInfo = flight.airline != nil ? "Airline: \(flight.airline!)" : "No airline specified"
        
        let content = """
        \(timeContext): Flight \(flight.number)
        \(airlineInfo)
        From: \(flight.departureName) (\(flight.departureCode))
        To: \(flight.arrivalName) (\(flight.arrivalCode))
        Departure: \(flight.departureDate.formatted(date: .long, time: .shortened))
        Arrival: \(flight.arrivalDate.formatted(date: .long, time: .shortened))
        """
        
        memoryService.addMemory(content: content, userId: userId, completion: completion)
    }
}

// Airport selection view
struct AirportSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAirport: Airport?
    let airports: [Airport]
    @State private var searchText = ""
    
    var filteredAirports: [Airport] {
        if searchText.isEmpty {
            return airports
        } else {
            return airports.filter { airport in
                airport.name.localizedCaseInsensitiveContains(searchText) ||
                airport.code.localizedCaseInsensitiveContains(searchText) ||
                airport.city.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredAirports) { airport in
                    Button(action: {
                        selectedAirport = airport
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(airport.city)")
                                    .font(.headline)
                                Text("\(airport.name) (\(airport.code))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedAirport?.code == airport.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .navigationTitle("Select Airport")
            .searchable(text: $searchText, prompt: "Search airports")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
} 