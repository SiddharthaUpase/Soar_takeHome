import SwiftUI

struct TripsTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var trips: [Trip] = []
    @State private var isLoading = true
    @State private var showingAddTripSheet = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading trips...")
            } else if trips.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "airplane.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("No trips yet")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Tap the + button to add your first trip")
                        .foregroundColor(.secondary)
                    
                    Button(action: { showingAddTripSheet = true }) {
                        Text("Add Trip")
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
                    ForEach(trips) { trip in
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            TripRowView(trip: trip)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .refreshable {
                    loadTrips()
                }
            }
        }
        .navigationTitle("My Trips")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTripSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTripSheet, onDismiss: {
            loadTrips()
        }) {
            AddTripView()
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
            loadTrips()
        }
    }
    
    private func loadTrips() {
        guard let userId = authViewModel.currentUser?.id else {
            errorMessage = "You need to be logged in to view trips"
            showingErrorAlert = true
            isLoading = false
            return
        }
        
        isLoading = true
        
        let tripService = TripService()
        tripService.fetchTrips(for: userId) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let fetchedTrips):
                    self.trips = fetchedTrips.sorted { $0.startDate < $1.startDate }
                case .failure(let error):
                    errorMessage = "Failed to load trips: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
}

struct TripRowView: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trip.name)
                .font(.headline)
            
            Text("\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) - \(trip.endDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Label("\(trip.flights.count)", systemImage: "airplane")
                    .font(.caption)
                
                Label("\(trip.accommodations.count)", systemImage: "house")
                    .font(.caption)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
} 