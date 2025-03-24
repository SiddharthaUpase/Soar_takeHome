import Foundation

class MemoryService {
    private let apiKey: String
    private let baseURL = "https://api.mem0.ai/v1"
    
    init(apiKey: String = "m0-tAWvlXyuAupKPpXVORG7DDmx4HuQzRLL88EMtna3") {
        self.apiKey = apiKey
    }
    
    // Add a memory to Mem0
    func addMemory(content: String, userId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/memories/") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Format assistant response based on the content
        let assistantResponse = "I've noted the following information: \(content)"
        
        let body: [String: Any] = [
            "messages": [
                ["role": "user", "content": content],
                ["role": "assistant", "content": assistantResponse]
            ],
            "user_id": userId,
            "output_format": "v1.1",
            "metadata": [
                "content_type": "travel_info",
                "app": "soar"
            ],
            "version": "v2"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode)))
                return
            }
            
            completion(.success(true))
        }.resume()
    }
    
    // Search memories in Mem0 and return raw response
    func searchMemories(query: String, userId: String, completion: @escaping (Result<[MemoryItem], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/memories/search/?version=v2") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "query": query,
            "user_id": userId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            do {
                // The response is an array of memory items
                let memoryItems = try JSONDecoder().decode([MemoryItem].self, from: data)
                completion(.success(memoryItems))
            } catch {
                print("Decoding error: \(error)")
                // If decoding fails, return the raw response as string for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw response: \(responseString)")
                }
                completion(.failure(error))
            }
        }.resume()
    }
}

// Define a MemoryItem struct to represent the response format
struct MemoryItem: Codable {
    let id: String
    let memory: String
    let userId: String
    let metadata: [String: String]?
    let categories: [String]?
    let immutable: Bool?
    let createdAt: String
    let updatedAt: String
    let expirationDate: String?
    let score: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case memory
        case userId = "user_id"
        case metadata
        case categories
        case immutable
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expirationDate = "expiration_date"
        case score
    }
} 