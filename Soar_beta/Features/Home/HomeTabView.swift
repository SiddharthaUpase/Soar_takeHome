import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with greeting
                HStack {
                    VStack(alignment: .leading) {
                        Text("Hello,")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text(authViewModel.currentUser?.fullname ?? "Traveler")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    // Profile image or icon
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                // Upcoming trips section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Upcoming Trips")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        NavigationLink(destination: TripsTabView()) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let upcomingTrips = getUpcomingTrips(), !upcomingTrips.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(upcomingTrips) { trip in
                                    NavigationLink(destination: TripDetailView(trip: trip)) {
                                        HomeTripCard(trip: trip)
                                            .frame(width: 280, height: 200)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        Text("No upcoming trips")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding(.top)
                
                // Upcoming flights section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Upcoming Flights")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        NavigationLink(destination: FlightsTabView()) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let upcomingFlights = getUpcomingFlights(), !upcomingFlights.isEmpty {
                        ForEach(upcomingFlights) { booking in
                            NavigationLink(destination: FlightDetailView(flightBooking: booking)) {
                                FlightCard(flightBooking: booking)
                            }
                        }
                    } else {
                        Text("No upcoming flights")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Home")
    }
    
    // Helper method to get upcoming trips
    private func getUpcomingTrips() -> [Trip]? {
        let now = Date()
        let upcomingTrips = authViewModel.trips
            .filter { $0.endDate > now }
            .sorted { $0.startDate < $1.startDate }
        
        return upcomingTrips.isEmpty ? nil : Array(upcomingTrips.prefix(5))
    }
    
    // Helper method to get upcoming flights
    private func getUpcomingFlights() -> [FlightBooking]? {
        let now = Date()
        let upcomingFlights = authViewModel.flightBookings
            .filter { $0.flight.departureDate > now }
            .sorted { $0.flight.departureDate < $1.flight.departureDate }
        
        return upcomingFlights.isEmpty ? nil : Array(upcomingFlights.prefix(3))
    }
}

struct HomeTripCard: View {
    let trip: Trip
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image or color
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.8))
            
            // Trip details overlay
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) - \(trip.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                HStack {
                    Image(systemName: "airplane.departure")
                    Text("\(trip.flights.count) Flights")
                    
                    Image(systemName: "bed.double")
                        .padding(.leading, 8)
                    Text("\(trip.accommodations.count) Stays")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, 4)
            }
            .padding()
        }
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

struct FlightCard: View {
    let flightBooking: FlightBooking
    
    var body: some View {
        HStack {
            // Airline logo or placeholder
            Image(systemName: "airplane.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
                .padding(.trailing, 8)
            
            // Flight details
            VStack(alignment: .leading, spacing: 4) {
                Text("Flight \(flightBooking.flight.number)")
                    .font(.headline)
                
                HStack {
                    Text(flightBooking.flight.departureCode)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    
                    Text(flightBooking.flight.arrivalCode)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Text("\(flightBooking.flight.departureDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Chevron or other indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
} 