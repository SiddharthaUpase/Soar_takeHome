import SwiftUI

struct AddTripView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = AddTripViewModel()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Error"
    @State private var isSaving = false
    @State private var confirmingDeleteFlight: Int? = nil
    @State private var confirmingDeleteAccommodation: Int? = nil
    
    var body: some View {
        NavigationView {
            Form {
                // Trip details section
                Section(header: Text("Trip Details")) {
                    TextField("Trip Name", text: $viewModel.tripName)
                        .autocapitalization(.words)
                    
                    DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                    
                    DatePicker("End Date", selection: $viewModel.endDate, displayedComponents: .date)
                        .onChange(of: viewModel.startDate) { _ in
                            if viewModel.endDate < viewModel.startDate {
                                viewModel.endDate = viewModel.startDate.addingTimeInterval(86400) // Next day
                            }
                        }
                }
                
                // Flights section
                Section {
                    ForEach(viewModel.flights.indices, id: \.self) { index in
                        FlightFormView(
                            flight: $viewModel.flights[index],
                            airports: viewModel.airportOptions,
                            canDelete: viewModel.flights.count > 1
                        ) {
                            // Show confirmation dialog before deleting
                            confirmingDeleteFlight = index
                        }
                        
                        if index < viewModel.flights.count - 1 {
                            Divider()
                                .padding(.vertical, 8)
                        }
                    }
                    
                    // Add a more prominent button to add flights
                    Button(action: { viewModel.addFlight() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Another Flight")
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Flights")
                } footer: {
                    if viewModel.flights.isEmpty {
                        Text("At least one flight is required")
                    }
                }
                
                // Accommodations section
                Section {
                    ForEach(viewModel.accommodations.indices, id: \.self) { index in
                        AccommodationFormView(
                            accommodation: $viewModel.accommodations[index],
                            canDelete: viewModel.accommodations.count > 1
                        ) {
                            // Show confirmation dialog before deleting
                            confirmingDeleteAccommodation = index
                        }
                        
                        if index < viewModel.accommodations.count - 1 {
                            Divider()
                                .padding(.vertical, 8)
                        }
                    }
                    
                    // Add a more prominent button to add accommodations
                    Button(action: { viewModel.addAccommodation() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Another Accommodation")
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Accommodations")
                } footer: {
                    if viewModel.accommodations.isEmpty {
                        Text("At least one accommodation is required")
                    }
                }
                
                // Save button
                Section {
                    Button(action: saveTrip) {
                        HStack {
                            Spacer()
                            Text("Save Trip")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.isFormValid || isSaving)
                    .listRowBackground(viewModel.isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add New Trip")
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
                            Text("Saving trip...")
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
            .confirmationDialog(
                "Are you sure you want to delete this flight?",
                isPresented: Binding(
                    get: { confirmingDeleteFlight != nil },
                    set: { if !$0 { confirmingDeleteFlight = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let index = confirmingDeleteFlight {
                        viewModel.removeFlight(at: index)
                    }
                    confirmingDeleteFlight = nil
                }
                
                Button("Cancel", role: .cancel) {
                    confirmingDeleteFlight = nil
                }
            }
            .confirmationDialog(
                "Are you sure you want to delete this accommodation?",
                isPresented: Binding(
                    get: { confirmingDeleteAccommodation != nil },
                    set: { if !$0 { confirmingDeleteAccommodation = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let index = confirmingDeleteAccommodation {
                        viewModel.removeAccommodation(at: index)
                    }
                    confirmingDeleteAccommodation = nil
                }
                
                Button("Cancel", role: .cancel) {
                    confirmingDeleteAccommodation = nil
                }
            }
        }
    }
    
    private func saveTrip() {
        guard let userId = authViewModel.currentUser?.id else {
            alertTitle = "Error"
            alertMessage = "You must be logged in to save a trip."
            showingAlert = true
            return
        }
        
        if !viewModel.isFormValid {
            alertTitle = "Invalid Form"
            alertMessage = "Please complete all required fields."
            showingAlert = true
            return
        }
        
        isSaving = true
        
        // 1. Create trip object from form data
        let trip = viewModel.buildTrip(userId: userId)
        
        // 2. Create a reference to the TripService
        let tripService = TripService()
        
        // 3. Save to database
        tripService.saveTrip(trip) { result in
            switch result {
            case .success:
                // 4. Always store detailed information in Memory Service regardless of date
                trip.storeDetailedInMemory { memoryResult in
                    DispatchQueue.main.async {
                        isSaving = false
                        dismiss()
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    isSaving = false
                    alertTitle = "Error"
                    alertMessage = "Error saving trip: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
} 