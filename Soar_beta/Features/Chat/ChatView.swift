import SwiftUI

struct ChatView: View {
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(id: "1", isUser: false, text: "Hi there! I'm your AI travel assistant. How can I help with your travel plans?", timestamp: Date().addingTimeInterval(-3600)),

    ]
    @State private var scrollToBottom = false
    @StateObject private var chatHelper = ChatMemoryHelper()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header with AI assistant avatar
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading) {
                    Text("Soar Assistant")
                        .font(.headline)
                    Text("AI-powered travel companion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Add clear chat button
                Button(action: clearChat) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.95))
            .shadow(color: Color.black.opacity(0.1), radius: 2, y: 2)
            
            // Messages area with padding at bottom to avoid input overlay
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 18) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16) // Add space at bottom of messages
                    
                    // Invisible spacer view to help with scrolling
                    Color.clear
                        .frame(height: 1)
                        .id("bottomID")
                }
                .onChange(of: messages.count) { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        scrollView.scrollTo("bottomID", anchor: .bottom)
                    }
                }
                .onChange(of: scrollToBottom) { shouldScroll in
                    if shouldScroll {
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollView.scrollTo("bottomID", anchor: .bottom)
                        }
                        // Reset the flag
                        scrollToBottom = false
                    }
                }
                .onAppear {
                    scrollView.scrollTo("bottomID", anchor: .bottom)
                }
            }
            
            // Message input field with clear separation from messages
            VStack(spacing: 0) {
                Divider()
                    .padding(.top, 8)
                
                VStack(spacing: 8) {
                    // Input field and send button
                    HStack {
                        TextField("Ask me about your trips...", text: $messageText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(24)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(messageText.isEmpty ? Color.gray : Color.purple)
                                .cornerRadius(19)
                        }
                        .disabled(messageText.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    // Quick suggestions below the input field
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(["Next flight?", "Weather in Athens", "Trip details"], id: \.self) { suggestion in
                                Button(action: {
                                    messageText = suggestion
                                    sendMessage()
                                }) {
                                    Text(suggestion)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.1))
                                        .foregroundColor(.purple)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 40)
                    .padding(.bottom, 8)
                }
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendMessage() {
        if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Add user message
            let userMessage = ChatMessage(
                id: UUID().uuidString,
                isUser: true,
                text: messageText,
                timestamp: Date()
            )
            messages.append(userMessage)
            
            // Clear input field
            let userQuery = messageText
            messageText = ""
            
            // Show typing indicator
            let typingMessage = ChatMessage(
                id: "typing-\(UUID().uuidString)",
                isUser: false,
                text: "...",
                timestamp: Date(),
                isTyping: true
            )
            messages.append(typingMessage)
            
            // Get user ID from auth view model
            let userId = authViewModel.currentUser?.id ?? "unknown-user"
            
            // Query memory service for a response
            chatHelper.processUserMessage(userQuery, userId: userId) { response in
                // Remove typing indicator
                DispatchQueue.main.async {
                    self.messages.removeAll(where: { $0.id == typingMessage.id })
                    
                    // Add AI response from memory
                    let aiResponse = ChatMessage(
                        id: UUID().uuidString,
                        isUser: false,
                        text: response,
                        timestamp: Date()
                    )
                    self.messages.append(aiResponse)
                    
                    // Force scroll to bottom after adding AI response
                    self.scrollToBottom = true
                }
            }
        }
    }
    
    // Add function to clear chat
    private func clearChat() {
        // Keep only the first welcome message
        if let welcomeMessage = messages.first {
            messages = [welcomeMessage]
        } else {
            messages = []
        }
    }
}

struct ChatMessage: Identifiable {
    let id: String
    let isUser: Bool
    let text: String
    let timestamp: Date
    var isTyping: Bool = false
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
                
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.leading, 60)
                
                // User avatar
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            } else {
                // AI avatar
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.purple)
                
                if message.isTyping {
                    // Typing indicator
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .frame(width: 7, height: 7)
                                .foregroundColor(Color.gray.opacity(0.5))
                                .offset(y: message.isTyping ? -3 : 0)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(0.2 * Double(index)),
                                    value: UUID() // Forces continuous animation
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.trailing, 60)
                    .onAppear {
                        // No longer needed with the value-based animation
                    }
                } else {
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.trailing, 60)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
} 