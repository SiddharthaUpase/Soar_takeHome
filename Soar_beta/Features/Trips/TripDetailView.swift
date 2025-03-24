import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Trip header
                VStack(alignment: .leading, spacing: 8) {
                    Text(trip.name)
                        .font(.largeTitle)
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
                }
                .padding(.horizontal)
                
                // Flights section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Flights")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ForEach(trip.flights) { flight in
                        FlightRowView(flight: flight)
                            .padding(.horizontal)
                    }
                }
                
                // Accommodations section
                if !trip.accommodations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accommodations")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(trip.accommodations) { accommodation in
                            AccommodationRowView(accommodation: accommodation)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FlightRowView: View {
    let flight: Flight
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(flight.number)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(flight.departureCode)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(flight.departureName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(dateFormatter.string(from: flight.departureDate))
                        .font(.caption)
                }
                
                Spacer()
                
                Image(systemName: "airplane")
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(flight.arrivalCode)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(flight.arrivalName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(dateFormatter.string(from: flight.arrivalDate))
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AccommodationRowView: View {
    let accommodation: Accommodation
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(accommodation.name)
                .font(.headline)
            
            Text(accommodation.agent)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(accommodation.address)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                
                Text("\(dateFormatter.string(from: accommodation.checkInDate)) - \(dateFormatter.string(from: accommodation.checkOutDate))")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 