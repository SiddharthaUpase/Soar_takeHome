import Foundation

struct User: Identifiable, Codable {
    var id: String
    let fullname: String
    let email: String
    let createdAt: Date
    
    init(id: String, fullname: String, email: String) {
        self.id = id
        self.fullname = fullname
        self.email = email
        self.createdAt = Date()
    }
} 