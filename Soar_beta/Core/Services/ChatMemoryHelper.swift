import Foundation
import Combine

class ChatMemoryHelper: ObservableObject {
    private let memoryService: MemoryService
    private let openAIService: OpenAIService
    @Published var isProcessing = false
    
    init(memoryService: MemoryService = MemoryService(), 
         openAIService: OpenAIService = OpenAIService(apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "ADD_API_KEY_HERE")) {
        self.memoryService = memoryService
        self.openAIService = openAIService
    }
    
    func retrieveRelevantMemories(for query: String, userId: String, completion: @escaping (String?) -> Void) {
        isProcessing = true
        
        memoryService.searchMemories(query: query, userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                switch result {
                case .success(let memoryItems):
                    // Format the memory items and pass the formatted string
                    if let formattedMemories = self?.formatMemoriesForDisplay(memoryItems) {
                        completion(formattedMemories)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    print("Failed to retrieve memories: \(error)")
                    completion("Error retrieving memories: \(error)")
                }
            }
        }
    }
    
    // Format memories for display in chat and/or LLM analysis
    func formatMemoriesForDisplay(_ memories: [MemoryItem]) -> String {
        guard !memories.isEmpty else {
            return "No relevant memories found."
        }
        
        // Sort memories by relevance score (if available)
        let sortedMemories = memories.sorted { 
            ($0.score ?? 0) > ($1.score ?? 0) 
        }
        
        var formattedOutput = "Here's what I found in your travel information:\n\n"
        
        for (index, memory) in sortedMemories.enumerated() {
            formattedOutput += "Memory \(index + 1): \(memory.memory)\n"
            
            // Only add relevance if score exists
            if let score = memory.score {
                let relevancePercentage = Int(score * 100)
                formattedOutput += "Relevance: \(relevancePercentage)%\n"
            }
            
            // Add a separator between memories
            if index < sortedMemories.count - 1 {
                formattedOutput += "\n---\n\n"
            }
        }
        
        return formattedOutput
    }
    
    // Enhanced method to process messages with both memory and OpenAI
    func processUserMessage(_ message: String, userId: String, completion: @escaping (String) -> Void) {
        isProcessing = true
        
        // Step 1: Classify the message type
        openAIService.classifyMessageType(message: message) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let messageType):
                switch messageType {
                case .query:
                    // Handle as a query (existing flow)
                    self.handleQuery(message, userId: userId, completion: completion)
                    
                case .statement:
                    // Handle as a statement (acknowledge + store in memory)
                    self.handleStatement(message, userId: userId, completion: completion)
                    
                case .webSearchQuery:
                    // Handle as a web search query
                    self.handleWebSearchQuery(message, completion: completion)
                }
                
            case .failure(let error):
                // Fallback to treating as a query if classification fails
                print("Classification error: \(error)")
                self.handleQuery(message, userId: userId, completion: completion)
            }
        }
    }
    
    // Add this method to handle queries (mostly existing code)
    private func handleQuery(_ query: String, userId: String, completion: @escaping (String) -> Void) {
        // Step 1: Get relevant memories from Mem0
        memoryService.searchMemories(query: query, userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let memories):
                // If we have relevant memories, send them to OpenAI
                if !memories.isEmpty {
                    // Sort by relevance and take top 3
                    let topMemories = memories.sorted { ($0.score ?? 0) > ($1.score ?? 0) }.prefix(3)
                    
                    // Step 2: Generate AI response with memories as context
                    self.openAIService.generateResponse(userQuery: query, memories: Array(topMemories)) { aiResult in
                        DispatchQueue.main.async {
                            self.isProcessing = false
                            
                            switch aiResult {
                            case .success(let aiResponse):
                                // Return the AI-generated response
                                completion(aiResponse)
                            case .failure(let error):
                                print("OpenAI error: \(error)")
                                // Fallback to simpler response if OpenAI fails
                                let fallbackResponse = self.createFallbackResponse(from: topMemories)
                                completion(fallbackResponse)
                            }
                        }
                    }
                } else {
                    // No memories found, provide a generic response
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        completion("I don't have specific information about that. Could you ask something about your trips or flights?")
                    }
                }
                
            case .failure(let error):
                print("Memory service error: \(error)")
                // Handle memory service failure
                DispatchQueue.main.async {
                    self.isProcessing = false
                    completion("I'm having trouble accessing your travel information right now. Please try again later.")
                }
            }
        }
    }
    
    // Add this method to handle statements
    private func handleStatement(_ statement: String, userId: String, completion: @escaping (String) -> Void) {
        // Step 1: Generate a personalized acknowledgment using OpenAI
        openAIService.generateAcknowledgment(for: statement) { [weak self] result in
            guard let self = self else { return }
            
            var acknowledgment = "Thanks for sharing that information!"
            
            if case .success(let generatedAcknowledgment) = result {
                acknowledgment = generatedAcknowledgment
            }
            
            // Step 2: Store the statement in memory
            self.memoryService.addMemory(content: statement, userId: userId) { result in
                switch result {
                case .success:
                    print("Successfully stored statement in memory")
                case .failure(let error):
                    print("Failed to store statement: \(error)")
                }
            }
            
            // Return the acknowledgment
            DispatchQueue.main.async {
                self.isProcessing = false
                completion(acknowledgment)
            }
        }
    }
    
    // Create a simple fallback response if OpenAI fails
    private func createFallbackResponse(from memories: ArraySlice<MemoryItem>) -> String {
        var response = "Based on your travel information:\n\n"
        
        for (index, memory) in memories.enumerated() {
            response += "• \(memory.memory)\n"
            
            if index < memories.count - 1 {
                response += "\n"
            }
        }
        
        return response
    }
    
    // Add this method to handle web search queries
    private func handleWebSearchQuery(_ query: String, completion: @escaping (String) -> Void) {
        // Use the OpenAI service to handle web search queries
        openAIService.handleWebSearchQuery(userQuery: query) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                
                switch result {
                case .success(let response):
                    completion(response)
                case .failure(let error):
                    print("Web search error: \(error)")
                    completion("I'm having trouble searching for that information right now. Please try again later.")
                }
            }
        }
    }
} 
