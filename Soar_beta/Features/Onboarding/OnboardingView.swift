import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var currentStep = 0
    @State private var isLoading = false
    @State private var showCompletionAlert = false
    
    // Travel preferences
    @State private var selectedDestinationTypes: [String] = []
    @State private var selectedDestinations: [String] = []
    @State private var newDestination: String = ""
    @State private var selectedAccommodations: [String] = []
    @State private var budgetRange: String = "Mid-range"
    @State private var travelStyle: String = "Balanced"
    @State private var selectedActivities: [String] = []
    @State private var selectedDietaryRestrictions: [String] = []
    @State private var selectedSeasons: [String] = []
    
    // Available options
    let destinationTypes = ["Beach", "Mountains", "City", "Countryside", "Historic", "Adventure", "Cultural", "Relaxation"]
    let popularDestinations = ["Paris", "Tokyo", "New York", "Bali", "London", "Rome", "Sydney", "Dubai", "Cancun", "Barcelona"]
    let accommodationTypes = ["Hotel", "Resort", "Vacation Rental", "Hostel", "Camping", "Luxury", "Budget"]
    let budgetRanges = ["Budget", "Mid-range", "Luxury"]
    let travelStyles = ["Relaxed", "Balanced", "Packed Itinerary"]
    let activities = ["Sightseeing", "Shopping", "Food Tours", "Hiking", "Swimming", "Nightlife", "Museums", "Local Experiences", "Wildlife"]
    let dietaryRestrictions = ["None", "Vegetarian", "Vegan", "Gluten-Free", "Halal", "Kosher", "Nut Allergy", "Seafood Allergy"]
    let seasons = ["Spring", "Summer", "Fall", "Winter", "Any"]
    
    var body: some View {
        ZStack {
            VStack {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: 6.0)
                    .padding()
                
                // Title
                Text("Let's Get to Know Your Travel Style")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                
                // Content based on current step
                Group {
                    switch currentStep {
                    case 0:
                        destinationTypeView
                    case 1:
                        specificDestinationsView
                    case 2:
                        accommodationView
                    case 3:
                        budgetAndStyleView
                    case 4:
                        activitiesView
                    case 5:
                        dietaryAndSeasonView
                    default:
                        Text("Unknown step")
                    }
                }
                .padding()
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if currentStep < 5 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canAdvance())
                    } else {
                        Button("Complete") {
                            savePreferences()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canAdvance())
                    }
                }
                .padding()
            }
            .padding()
            .disabled(isLoading)
            
            if isLoading {
                ProgressView("Saving your preferences...")
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .alert("Preferences Saved", isPresented: $showCompletionAlert) {
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Your travel preferences have been saved. We'll use these to enhance your experience.")
        }
    }
    
    private var destinationTypeView: some View {
        VStack(alignment: .leading) {
            Text("What types of destinations do you prefer?")
                .font(.headline)
                .padding(.bottom)
            
            Text("Select all that apply")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(destinationTypes, id: \.self) { type in
                        Button(action: {
                            toggleSelection(type, in: &selectedDestinationTypes)
                        }) {
                            Text(type)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedDestinationTypes.contains(type) ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedDestinationTypes.contains(type) ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private var specificDestinationsView: some View {
        VStack(alignment: .leading) {
            Text("Do you have specific destinations in mind?")
                .font(.headline)
                .padding(.bottom)
            
            Text("Select from popular destinations or add your own")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(popularDestinations, id: \.self) { destination in
                        Button(action: {
                            toggleSelection(destination, in: &selectedDestinations)
                        }) {
                            Text(destination)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedDestinations.contains(destination) ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedDestinations.contains(destination) ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                    }
                }
            }
            
            HStack {
                TextField("Add another destination...", text: $newDestination)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                
                Button(action: {
                    if !newDestination.isEmpty && !selectedDestinations.contains(newDestination) {
                        selectedDestinations.append(newDestination)
                        newDestination = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(newDestination.isEmpty)
            }
            .padding(.top)
            
            if !selectedDestinations.isEmpty {
                Text("Your selected destinations:")
                    .font(.subheadline)
                    .padding(.top)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(selectedDestinations, id: \.self) { destination in
                            if !popularDestinations.contains(destination) {
                                HStack {
                                    Text(destination)
                                    Button(action: {
                                        selectedDestinations.removeAll { $0 == destination }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(20)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var accommodationView: some View {
        VStack(alignment: .leading) {
            Text("What types of accommodations do you prefer?")
                .font(.headline)
                .padding(.bottom)
            
            Text("Select all that apply")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(accommodationTypes, id: \.self) { type in
                        Button(action: {
                            toggleSelection(type, in: &selectedAccommodations)
                        }) {
                            Text(type)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedAccommodations.contains(type) ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedAccommodations.contains(type) ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private var budgetAndStyleView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading) {
                Text("What's your typical travel budget?")
                    .font(.headline)
                    .padding(.bottom, 8)
                
                Picker("Budget Range", selection: $budgetRange) {
                    ForEach(budgetRanges, id: \.self) { range in
                        Text(range).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            VStack(alignment: .leading) {
                Text("How do you like to plan your days?")
                    .font(.headline)
                    .padding(.bottom, 8)
                
                Picker("Travel Style", selection: $travelStyle) {
                    ForEach(travelStyles, id: \.self) { style in
                        Text(style).tag(style)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
    
    private var activitiesView: some View {
        VStack(alignment: .leading) {
            Text("What activities do you enjoy while traveling?")
                .font(.headline)
                .padding(.bottom)
            
            Text("Select all that apply")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(activities, id: \.self) { activity in
                        Button(action: {
                            toggleSelection(activity, in: &selectedActivities)
                        }) {
                            Text(activity)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedActivities.contains(activity) ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedActivities.contains(activity) ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private var dietaryAndSeasonView: some View {
        VStack(alignment: .leading) {
            Text("Do you have any dietary restrictions?")
                .font(.headline)
                .padding(.bottom)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(dietaryRestrictions, id: \.self) { restriction in
                        Button(action: {
                            toggleSelection(restriction, in: &selectedDietaryRestrictions)
                        }) {
                            Text(restriction)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedDietaryRestrictions.contains(restriction) ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedDietaryRestrictions.contains(restriction) ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                    }
                }
                
                Text("When do you prefer to travel?")
                    .font(.headline)
                    .padding(.vertical)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(seasons, id: \.self) { season in
                        Button(action: {
                            toggleSelection(season, in: &selectedSeasons)
                        }) {
                            Text(season)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedSeasons.contains(season) ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedSeasons.contains(season) ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private func toggleSelection(_ item: String, in array: inout [String]) {
        if array.contains(item) {
            array.removeAll { $0 == item }
        } else {
            array.append(item)
        }
    }
    
    private func canAdvance() -> Bool {
        switch currentStep {
        case 0:
            return !selectedDestinationTypes.isEmpty
        case 1:
            return true
        case 2:
            return !selectedAccommodations.isEmpty
        case 3:
            return !budgetRange.isEmpty && !travelStyle.isEmpty
        case 4:
            return !selectedActivities.isEmpty
        case 5:
            return !selectedSeasons.isEmpty
        default:
            return false
        }
    }
    
    private func savePreferences() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isLoading = true
        
        var finalDietaryRestrictions = selectedDietaryRestrictions
        if finalDietaryRestrictions.contains("None") {
            finalDietaryRestrictions = ["None"]
        }
        
        let preferences = TravelPreference(
            userId: userId,
            preferredDestinationTypes: selectedDestinationTypes,
            preferredDestinations: selectedDestinations,
            accommodationPreferences: selectedAccommodations,
            budgetRange: budgetRange,
            travelStyle: travelStyle,
            activityPreferences: selectedActivities,
            dietaryRestrictions: finalDietaryRestrictions,
            seasonalPreferences: selectedSeasons
        )
        
        authViewModel.saveTravelPreferences(preferences: preferences) { success in
            isLoading = false
            
            if success {
                showCompletionAlert = true
            } else {
                print("Failed to save travel preferences")
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AuthViewModel())
    }
} 