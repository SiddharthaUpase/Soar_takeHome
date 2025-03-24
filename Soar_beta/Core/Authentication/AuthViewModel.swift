import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var trips: [Trip] = []
    @Published var flightBookings: [FlightBooking] = []
    @Published var hasCompletedOnboarding: Bool = false
    @Published var travelPreferences: TravelPreference?
    
    private let travelDataService = TravelDataService()
    private let memorySyncService = MemorySyncService()
    
    init() {
        self.userSession = Auth.auth().currentUser
        
        // Fetch user data if user is logged in
        if let userSession = userSession {
            fetchUser(uid: userSession.uid)
            checkOnboardingStatus(uid: userSession.uid)
        }
    }
    
    // MARK: - Authentication Methods
    
    func login(withEmail email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                return
            }
            
            self.userSession = result?.user
            let uid = result?.user.uid ?? ""
            self.fetchUser(uid: uid)
            
            // Check onboarding status after login
            self.checkOnboardingStatus(uid: uid)
        }
    }
    
    func register(withEmail email: String, password: String, fullname: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                return
            }
            
            guard let user = result?.user else { return }
            self.userSession = user
            
            // Create user profile in Firestore
            let userData = User(id: user.uid, fullname: fullname, email: email)
            self.createUserRecord(user: userData)
            
            // New users should not have completed onboarding
            self.hasCompletedOnboarding = false
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
            self.trips = []
            self.flightBookings = []
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Firestore Methods
    
    private func createUserRecord(user: User) {
        let userData: [String: Any] = [
            "id": user.id,
            "fullname": user.fullname,
            "email": user.email
        ]
        
        Firestore.firestore().collection("users")
            .document(user.id)
            .setData(userData) { [weak self] error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                self?.currentUser = user
                self?.checkAndInitializeTravelData()
            }
    }
    
    private func fetchUser(uid: String) {
        isLoading = true
        
        Firestore.firestore().collection("users")
            .document(uid)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists, 
                      let data = snapshot.data() else {
                    self.isLoading = false
                    self.errorMessage = "User data not found"
                    return
                }
                
                if let id = data["id"] as? String,
                   let fullname = data["fullname"] as? String,
                   let email = data["email"] as? String {
                    self.currentUser = User(id: id, fullname: fullname, email: email)
                    
                    // Check and initialize travel data
                    self.checkAndInitializeTravelData()
                } else {
                    self.isLoading = false
                    self.errorMessage = "Failed to decode user data"
                }
            }
    }
    
    // MARK: - Travel Data Methods
    
    private func checkAndInitializeTravelData() {
        guard let userId = currentUser?.id else {
            isLoading = false
            return
        }
        
        // Check if user already has travel data
        travelDataService.checkUserHasData(userId: userId) { [weak self] hasData in
            guard let self = self else { return }
            
            if hasData {
                // User already has data, fetch it
                self.fetchTravelData(userId: userId)
            } else {
                // User doesn't have data, initialize from dummy data
                self.initializeTravelData()
            }
        }
    }
    
    private func initializeTravelData() {
        guard let userId = currentUser?.id else {
            isLoading = false
            return
        }
        
        travelDataService.parseDummyData(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // Successfully initialized data, now fetch it
                self.fetchTravelData(userId: userId)
            case .failure(let error):
                self.isLoading = false
                self.errorMessage = "Failed to initialize travel data: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchTravelData(userId: String) {
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup()
        
        // Fetch trips
        dispatchGroup.enter()
        db.collection("trips")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    dispatchGroup.leave()
                    return
                }
                
                if let error = error {
                    self.errorMessage = "Failed to fetch trips: \(error.localizedDescription)"
                } else if let documents = snapshot?.documents {
                    self.trips = documents.compactMap { document -> Trip? in
                        let data = document.data()
                        
                        // Parse flights array
                        let flightsData = data["flights"] as? [[String: Any]] ?? []
                        let flights = flightsData.compactMap { flightData -> Flight? in
                            guard 
                                let id = flightData["id"] as? String,
                                let number = flightData["number"] as? String,
                                let departureName = flightData["departureName"] as? String,
                                let departureCode = flightData["departureCode"] as? String,
                                let arrivalName = flightData["arrivalName"] as? String,
                                let arrivalCode = flightData["arrivalCode"] as? String,
                                let departureTimestamp = flightData["departureDate"] as? Timestamp,
                                let arrivalTimestamp = flightData["arrivalDate"] as? Timestamp
                            else { return nil }
                            
                            return Flight(
                                id: id,
                                number: number,
                                departureName: departureName,
                                departureCode: departureCode,
                                arrivalName: arrivalName,
                                arrivalCode: arrivalCode,
                                departureDate: departureTimestamp.dateValue(),
                                arrivalDate: arrivalTimestamp.dateValue()
                            )
                        }
                        
                        // Parse accommodations array
                        let accommodationsData = data["accommodations"] as? [[String: Any]] ?? []
                        let accommodations = accommodationsData.compactMap { accommodationData -> Accommodation? in
                            guard 
                                let id = accommodationData["id"] as? String,
                                let agent = accommodationData["agent"] as? String,
                                let name = accommodationData["name"] as? String,
                                let address = accommodationData["address"] as? String,
                                let checkInTimestamp = accommodationData["checkInDate"] as? Timestamp,
                                let checkOutTimestamp = accommodationData["checkOutDate"] as? Timestamp
                            else { return nil }
                            
                            return Accommodation(
                                id: id,
                                agent: agent,
                                name: name,
                                address: address,
                                checkInDate: checkInTimestamp.dateValue(),
                                checkOutDate: checkOutTimestamp.dateValue()
                            )
                        }
                        
                        guard 
                            let id = data["id"] as? String,
                            let name = data["name"] as? String,
                            let startTimestamp = data["startDate"] as? Timestamp,
                            let endTimestamp = data["endDate"] as? Timestamp,
                            let userId = data["userId"] as? String
                        else { return nil }
                        
                        return Trip(
                            id: id,
                            name: name,
                            flights: flights,
                            accommodations: accommodations,
                            startDate: startTimestamp.dateValue(),
                            endDate: endTimestamp.dateValue(),
                            userId: userId
                        )
                    }
                }
                
                dispatchGroup.leave()
            }
        
        // Fetch flight bookings
        dispatchGroup.enter()
        db.collection("flightBookings")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    dispatchGroup.leave()
                    return
                }
                
                if let error = error {
                    self.errorMessage = "Failed to fetch flight bookings: \(error.localizedDescription)"
                } else if let documents = snapshot?.documents {
                    self.flightBookings = documents.compactMap { document -> FlightBooking? in
                        let data = document.data()
                        
                        // Parse flight
                        guard 
                            let flightData = data["flight"] as? [String: Any],
                            let id = flightData["id"] as? String,
                            let number = flightData["number"] as? String,
                            let departureName = flightData["departureName"] as? String,
                            let departureCode = flightData["departureCode"] as? String,
                            let arrivalName = flightData["arrivalName"] as? String,
                            let arrivalCode = flightData["arrivalCode"] as? String,
                            let departureTimestamp = flightData["departureDate"] as? Timestamp,
                            let arrivalTimestamp = flightData["arrivalDate"] as? Timestamp
                        else { return nil }
                        
                        let flight = Flight(
                            id: id,
                            number: number,
                            departureName: departureName,
                            departureCode: departureCode,
                            arrivalName: arrivalName,
                            arrivalCode: arrivalCode,
                            departureDate: departureTimestamp.dateValue(),
                            arrivalDate: arrivalTimestamp.dateValue()
                        )
                        
                        guard 
                            let bookingId = data["id"] as? String,
                            let userId = data["userId"] as? String,
                            let isPartOfTrip = data["isPartOfTrip"] as? Bool
                        else { return nil }
                        
                        let tripId = data["tripId"] as? String
                        
                        return FlightBooking(
                            id: bookingId,
                            flight: flight,
                            userId: userId,
                            isPartOfTrip: isPartOfTrip,
                            tripId: tripId
                        )
                    }
                }
                
                dispatchGroup.leave()
            }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            
            // After fetching travel data, sync data to memory
            self.syncDataToMemory(userId: userId)
        }
    }
    
    private func fetchTravelData() {
        guard let userId = currentUser?.id else {
            isLoading = false
            return
        }
        
        fetchTravelData(userId: userId)
    }
    
    // MARK: - Memory Sync Methods
    
    private func syncDataToMemory(userId: String) {
        // Sync trips
        if !trips.isEmpty {
            memorySyncService.syncUserTripsToMemory(userId: userId, trips: trips) { successCount, failureCount in
                if successCount > 0 {
                    print("Successfully synced \(successCount) trips to memory")
                }
                
                if failureCount > 0 {
                    print("Failed to sync \(failureCount) trips to memory")
                }
            }
        }
        
        // Sync flight bookings
        if !flightBookings.isEmpty {
            memorySyncService.syncUserFlightBookingsToMemory(userId: userId, flightBookings: flightBookings) { successCount, failureCount in
                if successCount > 0 {
                    print("Successfully synced \(successCount) flight bookings to memory")
                }
                
                if failureCount > 0 {
                    print("Failed to sync \(failureCount) flight bookings to memory")
                }
            }
        }
    }
    
    func checkOnboardingStatus(uid: String) {
        Firestore.firestore().collection("userPreferences")
            .whereField("userId", isEqualTo: uid)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error checking onboarding status: \(error.localizedDescription)")
                    return
                }
                
                self.hasCompletedOnboarding = !(snapshot?.documents.isEmpty ?? true)
                
                if self.hasCompletedOnboarding {
                    self.fetchTravelPreferences(uid: uid)
                }
            }
    }
    
    private func fetchTravelPreferences(uid: String) {
        Firestore.firestore().collection("userPreferences")
            .whereField("userId", isEqualTo: uid)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching travel preferences: \(error.localizedDescription)")
                    return
                }
                
                if let document = snapshot?.documents.first {
                    let data = document.data()
                    
                    let id = data["id"] as? String ?? ""
                    let userId = data["userId"] as? String ?? ""
                    let preferredDestinationTypes = data["preferredDestinationTypes"] as? [String] ?? []
                    let preferredDestinations = data["preferredDestinations"] as? [String] ?? []
                    let accommodationPreferences = data["accommodationPreferences"] as? [String] ?? []
                    let budgetRange = data["budgetRange"] as? String ?? ""
                    let travelStyle = data["travelStyle"] as? String ?? ""
                    let activityPreferences = data["activityPreferences"] as? [String] ?? []
                    let dietaryRestrictions = data["dietaryRestrictions"] as? [String] ?? []
                    let seasonalPreferences = data["seasonalPreferences"] as? [String] ?? []
                    let createdAtTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                    
                    self.travelPreferences = TravelPreference(
                        id: id,
                        userId: userId,
                        preferredDestinationTypes: preferredDestinationTypes,
                        preferredDestinations: preferredDestinations,
                        accommodationPreferences: accommodationPreferences,
                        budgetRange: budgetRange,
                        travelStyle: travelStyle,
                        activityPreferences: activityPreferences,
                        dietaryRestrictions: dietaryRestrictions,
                        seasonalPreferences: seasonalPreferences,
                        createdAt: createdAtTimestamp.dateValue()
                    )
                }
            }
    }
    
    func saveTravelPreferences(preferences: TravelPreference, completion: @escaping (Bool) -> Void) {
        guard let userId = currentUser?.id else {
            completion(false)
            return
        }
        
        let data: [String: Any] = [
            "id": preferences.id,
            "userId": userId,
            "preferredDestinationTypes": preferences.preferredDestinationTypes,
            "preferredDestinations": preferences.preferredDestinations,
            "accommodationPreferences": preferences.accommodationPreferences,
            "budgetRange": preferences.budgetRange,
            "travelStyle": preferences.travelStyle,
            "activityPreferences": preferences.activityPreferences,
            "dietaryRestrictions": preferences.dietaryRestrictions,
            "seasonalPreferences": preferences.seasonalPreferences,
            "createdAt": Timestamp(date: preferences.createdAt)
        ]
        
        // Save to Firestore
        Firestore.firestore().collection("userPreferences")
            .document(preferences.id)
            .setData(data) { [weak self] error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                if let error = error {
                    print("Error saving preferences: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                self.travelPreferences = preferences
                self.hasCompletedOnboarding = true
                
                // Save to memory service
                self.savePreferencesToMemory(preferences: preferences) { success in
                    completion(success)
                }
            }
    }
    
    private func savePreferencesToMemory(preferences: TravelPreference, completion: @escaping (Bool) -> Void) {
        // Create separate memories for each preference category for better retrieval
        let preferenceCategories: [(String, [String])] = [
            ("Destination Types", preferences.preferredDestinationTypes),
            ("Destinations", preferences.preferredDestinations),
            ("Accommodation", preferences.accommodationPreferences),
            ("Activities", preferences.activityPreferences),
            ("Dietary Restrictions", preferences.dietaryRestrictions),
            ("Seasonal Preferences", preferences.seasonalPreferences)
        ]
        
        let memoryService = MemoryService()
        let dispatchGroup = DispatchGroup()
        var successCount = 0
        var failureCount = 0
        
        for (category, items) in preferenceCategories {
            if !items.isEmpty {
                dispatchGroup.enter()
                let content = "My preferred \(category.lowercased()): \(items.joined(separator: ", "))"
                
                memoryService.addMemory(content: content, userId: preferences.userId) { result in
                    switch result {
                    case .success:
                        successCount += 1
                    case .failure:
                        failureCount += 1
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        // Add budget and travel style
        dispatchGroup.enter()
        let styleContent = "My travel style: Budget range: \(preferences.budgetRange), Planning style: \(preferences.travelStyle)"
        memoryService.addMemory(content: styleContent, userId: preferences.userId) { result in
            switch result {
            case .success:
                successCount += 1
            case .failure:
                failureCount += 1
            }
            dispatchGroup.leave()
        }
        
        // Also add the complete preferences as one entry for comprehensive retrieval
        let completeContent = """
        Travel Preferences Summary:
        - Destination Types: \(preferences.preferredDestinationTypes.joined(separator: ", "))
        - Destinations: \(preferences.preferredDestinations.joined(separator: ", "))
        - Accommodation: \(preferences.accommodationPreferences.joined(separator: ", "))
        - Budget Range: \(preferences.budgetRange)
        - Travel Style: \(preferences.travelStyle)
        - Activities: \(preferences.activityPreferences.joined(separator: ", "))
        - Dietary Restrictions: \(preferences.dietaryRestrictions.joined(separator: ", "))
        - Seasonal Preferences: \(preferences.seasonalPreferences.joined(separator: ", "))
        """
        
        dispatchGroup.enter()
        memoryService.addMemory(content: completeContent, userId: preferences.userId) { result in
            switch result {
            case .success:
                successCount += 1
            case .failure:
                failureCount += 1
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(failureCount == 0)
        }
    }
} 