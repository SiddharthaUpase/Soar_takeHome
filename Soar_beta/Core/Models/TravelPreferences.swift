import Foundation

struct TravelPreference: Identifiable, Codable {
    let id: String
    let userId: String
    let preferredDestinationTypes: [String]
    let preferredDestinations: [String]
    let accommodationPreferences: [String]
    let budgetRange: String
    let travelStyle: String
    let activityPreferences: [String]
    let dietaryRestrictions: [String]
    let seasonalPreferences: [String]
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         userId: String,
         preferredDestinationTypes: [String],
         preferredDestinations: [String] = [],
         accommodationPreferences: [String],
         budgetRange: String,
         travelStyle: String,
         activityPreferences: [String],
         dietaryRestrictions: [String] = [],
         seasonalPreferences: [String],
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.preferredDestinationTypes = preferredDestinationTypes
        self.preferredDestinations = preferredDestinations
        self.accommodationPreferences = accommodationPreferences
        self.budgetRange = budgetRange
        self.travelStyle = travelStyle
        self.activityPreferences = activityPreferences
        self.dietaryRestrictions = dietaryRestrictions
        self.seasonalPreferences = seasonalPreferences
        self.createdAt = createdAt
    }
} 