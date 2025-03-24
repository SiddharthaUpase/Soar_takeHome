import SwiftUI

struct FlightsTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var flightBookings: [FlightBooking] = []
    @State private var isLoading = true
    @State private var showingAddFlightSheet = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading flights...")
            } else if flightBookings.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "airplane.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("No flights yet")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Tap the + button to add your first flight")
                        .foregroundColor(.secondary)
                    
                    Button(action: { showingAddFlightSheet = true }) {
                        Text("Add Flight")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.top, 10)
                }
                .padding()
            } else {
                List {
                    ForEach(flightBookings) { booking in
                        NavigationLink(destination: FlightDetailView(flightBooking: booking)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(booking.flight.number)
                                        .font(.headline)
                                    
                                    HStack {
                                        Text(booking.flight.departureCode)
                                            .fontWeight(.semibold)
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.caption)
                                        
                                        Text(booking.flight.arrivalCode)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text("\(booking.flight.departureDate.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if booking.isPartOfTrip, let tripId = booking.tripId {
                                    Image(systemName: "bag")
                                        .foregroundColor(.blue)
                                        .help("Part of a trip")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    loadFlights()
                }
            }
        }
        .navigationTitle("Flight Bookings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddFlightSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddFlightSheet, onDismiss: {
            loadFlights()
        }) {
            AddFlightView()
                .environmentObject(authViewModel)
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            loadFlights()
        }
    }
    
    private func loadFlights() {
        guard let userId = authViewModel.currentUser?.id else {
            errorMessage = "You need to be logged in to view flights"
            showingErrorAlert = true
            isLoading = false
            return
        }
        
        isLoading = true
        
        let flightService = FlightService()
        flightService.fetchFlightBookings(for: userId) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let fetchedBookings):
                    self.flightBookings = fetchedBookings.sorted { $0.flight.departureDate < $1.flight.departureDate }
                case .failure(let error):
                    errorMessage = "Failed to load flights: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
} 