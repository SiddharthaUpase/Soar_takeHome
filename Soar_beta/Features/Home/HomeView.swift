import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                if let user = authViewModel.currentUser {
                    if authViewModel.isLoading {
                        ProgressView("Loading travel data...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Welcome header
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Welcome back,")
                                        .font(.title2)
                                    
                                    Text(user.fullname)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top)
                                
                                // Quick access cards
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        QuickAccessCard(
                                            icon: "airplane.departure",
                                            title: "My Trips",
                                            count: authViewModel.trips.count,
                                            color: .blue
                                        )
                                        
                                        QuickAccessCard(
                                            icon: "ticket",
                                            title: "Flight Bookings",
                                            count: authViewModel.flightBookings.count,
                                            color: .green
                                        )
                                        
                                        QuickAccessCard(
                                            icon: "bubble.left.and.bubble.right",
                                            title: "Chat",
                                            color: .purple
                                        )
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // Trips section
                                if !authViewModel.trips.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Upcoming Trips")
                                            .font(.headline)
                                        
                                        ForEach(authViewModel.trips) { trip in
                                            TripCard(trip: trip)
                                        }
                                    }
                                    .padding()
                                }
                                
                                // Flight bookings section
                                if !authViewModel.flightBookings.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Flight Bookings")
                                            .font(.headline)
                                        
                                        ForEach(authViewModel.flightBookings) { booking in
                                            FlightBookingCard(booking: booking)
                                        }
                                    }
                                    .padding()
                                }
                                
                                // No data message
                                if authViewModel.trips.isEmpty && authViewModel.flightBookings.isEmpty {
                                    VStack(spacing: 20) {
                                        Text("Your travel itineraries will appear here")
                                            .font(.headline)
                                        
                                        Image(systemName: "map")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(.gray.opacity(0.5))
                                        
                                        Text("No trips scheduled yet")
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    ProgressView("Loading profile...")
                }
            }
            .navigationBarTitle("Soar", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    authViewModel.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
            )
        }
    }
}

struct QuickAccessCard: View {
    let icon: String
    let title: String
    let count: Int?
    let color: Color
    
    init(icon: String, title: String, count: Int? = nil, color: Color) {
        self.icon = icon
        self.title = title
        self.count = count
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            if let count = count {
                Text("\(count)")
                    .font(.callout)
                    .padding(6)
                    .background(Color.white)
                    .foregroundColor(color)
                    .clipShape(Circle())
            }
        }
        .frame(width: 120, height: 120)
        .background(color)
        .cornerRadius(12)
    }
}

struct TripCard: View {
    let trip: Trip
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trip.name)
                .font(.title3)
                .fontWeight(.bold)
            
            HStack {
                Text("\(dateFormatter.string(from: trip.startDate)) - \(dateFormatter.string(from: trip.endDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(trip.flights.count) flights")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            // First and last destination
            if !trip.flights.isEmpty, let firstFlight = trip.flights.first, let lastFlight = trip.flights.last {
                HStack {
                    Text(firstFlight.departureCode)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                    
                    Text(lastFlight.arrivalCode)
                        .fontWeight(.semibold)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FlightBookingCard: View {
    let booking: FlightBooking
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(booking.flight.number)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(booking.flight.departureCode)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(booking.flight.departureName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(dateFormatter.string(from: booking.flight.departureDate))
                        .font(.caption)
                }
                
                Spacer()
                
                Image(systemName: "airplane")
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(booking.flight.arrivalCode)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(booking.flight.arrivalName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(dateFormatter.string(from: booking.flight.arrivalDate))
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 