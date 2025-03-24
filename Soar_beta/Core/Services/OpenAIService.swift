import Foundation

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateResponse(userQuery: String, memories: [MemoryItem], completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add current date for context
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let currentDate = dateFormatter.string(from: Date())
        
        // Format the memories into a prompt
        var memoryContext = "Here is relevant information from their travel profile:\n"
        for (index, memory) in memories.prefix(3).enumerated() {
            memoryContext += "\(index + 1). \(memory.memory)\n"
        }
        
        // Create the prompt for OpenAI with temporal awareness
        let prompt = """
        You are a travel assistant for the Soar app. Today's date is \(currentDate).
        
        The user has asked: "\(userQuery)"

        \(memoryContext)

        IMPORTANT TIME AWARENESS INSTRUCTIONS:
        - When responding about trips, be time-aware relative to today's date (\(currentDate))
        - If the user asks about "upcoming trips" or "future trips", only mention trips marked as UPCOMING TRIP
        - If the user asks about "past trips", only mention trips marked as PAST TRIP
        - If the user asks about "current trip", only mention trips marked as CURRENT TRIP
        - Pay careful attention to the temporal markers (PAST TRIP, CURRENT TRIP, UPCOMING TRIP) in the memory information
        
        Please craft a helpful, conversational response that addresses their question using this information.
        If the information doesn't fully answer their question, acknowledge what you know and what you don't.
        Keep your response friendly and concise.
        """
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": """
You are a helpful travel assistant for the Soar app.
You should provide concise, accurate responses based on the user's travel data. Follow these guidelines:
1. Keep responses under 2-3 sentences when possible
2. Be warm and personable, but prioritize factual information
3. Directly address the user's question without unnecessary preamble
4. If you don't have enough information, clearly state what you know and what you don't
5. Never invent travel details that aren't in the provided context
6. Use natural, conversational language while maintaining professionalism
7. Highlight key information like dates, locations, and confirmation numbers when relevant
"""
            ],
            ["role": "user", "content": prompt]
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500
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
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    enum MessageType {
        case query     // User is asking a question
        case statement // User is making a statement
        case webSearchQuery // User is asking something that needs web search
    }

    func classifyMessageType(message: String, completion: @escaping (Result<MessageType, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Determine if the following message is:
        1. A QUERY (asking for information that can be answered from user's existing travel profile)
        2. A STATEMENT (sharing information)
        3. A WEB_SEARCH (asking for information that requires real-time data like visa requirements, travel advisories, travel restrictions, flight status, currency exchange, weather forecasts, etc.)
        
        Respond with only one word: "QUERY", "STATEMENT", or "WEB_SEARCH".
        
        Message: "\(message)"
        """
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": "You are a message classifier that determines the type of user message."],
            ["role": "user", "content": prompt]
        ]
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo", // Using smaller model for efficiency
            "messages": messages,
            "temperature": 0.1,   // Low temperature for deterministic output
            "max_tokens": 10      // We only need a short response
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
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // Parse the response
                    let normalizedResponse = content.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                    
                    if normalizedResponse.contains("WEB_SEARCH") {
                        completion(.success(.webSearchQuery))
                    } else if normalizedResponse.contains("QUERY") {
                        completion(.success(.query))
                    } else if normalizedResponse.contains("STATEMENT") {
                        completion(.success(.statement))
                    } else {
                        // Default to query if classification is unclear
                        completion(.success(.query))
                    }
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func generateAcknowledgment(for statement: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        The user has shared this statement: "\(statement)"
        
        Generate a friendly, engaging, and personalized acknowledgment response that:
        1. Shows you understood what they shared
        2. Has a positive, upbeat tone
        3. Is brief (1-2 sentences)
        4. Feels natural in a travel assistant conversation
        """
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": "You are a helpful travel assistant chatbot that responds to users in a friendly, conversational way."],
            ["role": "user", "content": prompt]
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 100
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
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func handleWebSearchQuery(userQuery: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Match exactly the format from the working curl command
        let messages: [[String: Any]] = [
            ["role": "user", "content": userQuery]
        ]
        
        // Use the exact format from the working curl example
        let body: [String: Any] = [
            "model": "gpt-4o-search-preview",
            "web_search_options": [:],
            "messages": messages
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        // First API call with web search
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                // Include response body in error for better debugging
                var errorMessage = "HTTP Error \(httpResponse.statusCode)"
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    errorMessage += ": \(responseString)"
                }
                completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: ["responseBody": errorMessage])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let searchResults = message["content"] as? String {
                    
                    // Step 2: Format the results in app's tone
                    self?.formatWebSearchResults(searchResults: searchResults, originalQuery: userQuery, completion: completion)
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func formatWebSearchResults(searchResults: String, originalQuery: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add current date for context
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let currentDate = dateFormatter.string(from: Date())
        
        let prompt = """
        The user asked: "\(originalQuery)"
        
        Today's date is \(currentDate).
        
        Here is information found from a web search: 
        
        \(searchResults)
        
        Please reformat this information into a friendly, conversational response that:
        1. Addresses the user's query directly
        2. Is warm and personable like a travel assistant
        3. Keeps the tone consistent with the Soar app
        4. Is concise (3-4 sentences when possible)
        5. Highlights the most relevant facts for a traveler
        """
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": """
You are a helpful travel assistant for the Soar app.
You should provide concise, accurate responses based on the user's travel data. Follow these guidelines:
1. Keep responses under 2-3 sentences when possible
2. Be warm and personable, but prioritize factual information
3. Directly address the user's question without unnecessary preamble
4. Use natural, conversational language while maintaining professionalism
5. Highlight key information like dates, locations, and requirements when relevant
"""
            ],
            ["role": "user", "content": prompt]
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500
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
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
} 