import SwiftUI

struct AccommodationFormView: View {
    @Binding var accommodation: AccommodationFormModel
    let canDelete: Bool
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Accommodation Details")
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
            
            // Accommodation information group
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Name (e.g. Hilton Hotel, Airbnb)", text: $accommodation.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Address", text: $accommodation.address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Booking Agent (e.g. Booking.com, Airbnb)", text: $accommodation.agent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            } label: {
                Label("Property Information", systemImage: "house")
                    .font(.subheadline)
            }
            
            // Dates information
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    DatePicker("Check-in Date", selection: $accommodation.checkInDate, displayedComponents: .date)
                    
                    DatePicker("Check-out Date", selection: $accommodation.checkOutDate, displayedComponents: .date)
                        .onChange(of: accommodation.checkInDate) { _ in
                            if accommodation.checkOutDate < accommodation.checkInDate {
                                accommodation.checkOutDate = accommodation.checkInDate.addingTimeInterval(86400) // Next day
                            }
                        }
                    
                    // Show the number of nights
                    let nights = Calendar.current.dateComponents([.day], from: accommodation.checkInDate, to: accommodation.checkOutDate).day ?? 0
                    Text("\(nights) night\(nights == 1 ? "" : "s") stay")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            } label: {
                Label("Stay Duration", systemImage: "calendar")
                    .font(.subheadline)
            }
            
            // Show validation messages
            if !accommodation.name.isEmpty && 
               !accommodation.address.isEmpty && 
               accommodation.checkInDate < accommodation.checkOutDate {
                Text("✓ Accommodation information complete")
                    .foregroundColor(.green)
                    .font(.footnote)
                    .padding(.top, 4)
            } else {
                Text("Please complete all accommodation information")
                    .foregroundColor(.orange)
                    .font(.footnote)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
} 