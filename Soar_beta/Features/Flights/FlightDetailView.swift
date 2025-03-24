import SwiftUI

struct FlightDetailView: View {
    let flightBooking: FlightBooking
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }
    
    var tripName: String? {
        if flightBooking.isPartOfTrip, let tripId = flightBooking.tripId {
            return authViewModel.trips.first(where: { $0.id == tripId })?.name
        }
        return nil
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Flight header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Flight \(flightBooking.flight.number)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let tripName = tripName {
                        Text("Part of: \(tripName)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Flight card
                VStack(spacing: 24) {
                    // Departure
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DEPARTURE")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(flightBooking.flight.departureCode)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(flightBooking.flight.departureName)
                                .font(.headline)
                            
                            Text(dateFormatter.string(from: flightBooking.flight.departureDate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Flight path visualization
                    HStack(spacing: 0) {
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.blue)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "airplane")
                            .foregroundColor(.blue)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(.blue)
                        
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical)
                    
                    // Arrival
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ARRIVAL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(flightBooking.flight.arrivalCode)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(flightBooking.flight.arrivalName)
                                .font(.headline)
                            
                            Text(dateFormatter.string(from: flightBooking.flight.arrivalDate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Flight duration
                    HStack {
                        Image(systemName: "clock")
                        
                        Text("Duration: \(formatDuration(from: flightBooking.flight.departureDate, to: flightBooking.flight.arrivalDate))")
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                    .padding(.top)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Additional information placeholders
                Group {
                    InfoSection(title: "Airline", content: "Information about the airline would be shown here.")
                    
                    InfoSection(title: "Terminal Information", content: "Terminal and gate information would be shown here.")
                    
                    InfoSection(title: "Baggage", content: "Baggage allowance and policy would be shown here.")
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Flight Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDuration(from startDate: Date, to endDate: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: startDate, to: endDate)
        
        if let hours = components.hour, let minutes = components.minute {
            return "\(hours)h \(minutes)m"
        }
        
        return "Unknown"
    }
}

struct InfoSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 