import SwiftUI

struct FlightFormView: View {
    @Binding var flight: FlightFormModel
    let airports: [Airport]
    let canDelete: Bool
    let onDelete: () -> Void
    
    @State private var showingDepartureAirports = false
    @State private var showingArrivalAirports = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Flight Details")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                if canDelete {
                    Button(action: onDelete) {
                        Label("Remove", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            
            // Flight information group
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Airline (e.g. United, Delta)", text: $flight.airline)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            Text("Optional")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .background(Color(.systemBackground))
                                .opacity(flight.airline.isEmpty ? 1 : 0),
                            alignment: .trailing
                        )
                        .padding(.trailing, 8)
                    
                    TextField("Flight Number (e.g. UA123)", text: $flight.flightNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.namePhonePad)
                }
            } label: {
                Label("Airline Information", systemImage: "airplane")
                    .font(.subheadline)
            }
            
            // Departure information
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    // Departure airport dropdown
                    DisclosureGroup(
                        isExpanded: $showingDepartureAirports,
                        content: {
                            ScrollView(.vertical, showsIndicators: true) {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(airports) { airport in
                                        Button(action: {
                                            flight.departureAirport = airport
                                            showingDepartureAirports = false
                                        }) {
                                            HStack {
                                                Text("\(airport.city) - \(airport.name) (\(airport.code))")
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                Spacer()
                                                if flight.departureAirport.code == airport.code {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                            .contentShape(Rectangle())
                                            .padding(.vertical, 8)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        Divider()
                                    }
                                }
                            }
                            .frame(height: 200)
                        },
                        label: {
                            HStack {
                                Text("From:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(flight.departureAirport.code.isEmpty ? "Select Airport" : "\(flight.departureAirport.city) (\(flight.departureAirport.code))")
                                    .foregroundColor(flight.departureAirport.code.isEmpty ? .secondary : .primary)
                            }
                        }
                    )
                    .padding(.vertical, 4)
                    
                    DatePicker("Departure Date & Time", selection: $flight.departureDate)
                }
            } label: {
                Label("Departure", systemImage: "arrow.up.right")
                    .font(.subheadline)
            }
            
            // Arrival information
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    // Arrival airport dropdown
                    DisclosureGroup(
                        isExpanded: $showingArrivalAirports,
                        content: {
                            ScrollView(.vertical, showsIndicators: true) {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(airports) { airport in
                                        Button(action: {
                                            flight.arrivalAirport = airport
                                            showingArrivalAirports = false
                                        }) {
                                            HStack {
                                                Text("\(airport.city) - \(airport.name) (\(airport.code))")
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                Spacer()
                                                if flight.arrivalAirport.code == airport.code {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                            .contentShape(Rectangle())
                                            .padding(.vertical, 8)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        Divider()
                                    }
                                }
                            }
                            .frame(height: 200)
                        },
                        label: {
                            HStack {
                                Text("To:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(flight.arrivalAirport.code.isEmpty ? "Select Airport" : "\(flight.arrivalAirport.city) (\(flight.arrivalAirport.code))")
                                    .foregroundColor(flight.arrivalAirport.code.isEmpty ? .secondary : .primary)
                            }
                        }
                    )
                    .padding(.vertical, 4)
                    
                    DatePicker("Arrival Date & Time", selection: $flight.arrivalDate)
                }
            } label: {
                Label("Arrival", systemImage: "arrow.down.forward")
                    .font(.subheadline)
            }
            
            // Show validation messages
            if !flight.flightNumber.isEmpty && 
               !flight.departureAirport.code.isEmpty && !flight.arrivalAirport.code.isEmpty &&
               flight.departureDate < flight.arrivalDate {
                Text("✓ Flight information complete")
                    .foregroundColor(.green)
                    .font(.footnote)
                    .padding(.top, 4)
            } else {
                Text("Please complete all required flight information")
                    .foregroundColor(.orange)
                    .font(.footnote)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
} 