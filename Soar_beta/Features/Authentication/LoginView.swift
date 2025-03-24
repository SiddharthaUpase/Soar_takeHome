import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var tabSelection: TabSelection
    @State private var email = ""
    @State private var password = ""
    @State private var showRegistration = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "0A5BC3"), Color(hex: "0F82DF")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 25) {
                    // Logo and Welcome text
                    VStack(spacing: 20) {
                        Image(systemName: "airplane.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 8) {
                            Text("Welcome to Soar")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Your AI Travel Assistant")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Login form
                    VStack(spacing: 25) {
                        // Form container
                        VStack(spacing: 20) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.leading, 3)
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(Color(hex: "0A5BC3"))
                                        .frame(width: 20)
                                    
                                    TextField("", text: $email)
                                        .placeholder(when: email.isEmpty) {
                                            Text("Enter your email").foregroundColor(Color(hex: "0A5BC3").opacity(0.5))
                                        }
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .textContentType(.emailAddress)
                                        .focused($focusedField, equals: .email)
                                        .foregroundColor(Color(hex: "0A5BC3"))
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 4)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.leading, 3)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(Color(hex: "0A5BC3"))
                                        .frame(width: 20)
                                    
                                    SecureField("", text: $password)
                                        .placeholder(when: password.isEmpty) {
                                            Text("Enter your password").foregroundColor(Color(hex: "0A5BC3").opacity(0.5))
                                        }
                                        .textContentType(.password)
                                        .focused($focusedField, equals: .password)
                                        .foregroundColor(Color(hex: "0A5BC3"))
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Error message
                        if let errorMessage = authViewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.white)
                                .font(.caption)
                                .padding(.horizontal, 25)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.7))
                                .cornerRadius(8)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Login button
                        Button {
                            authViewModel.login(withEmail: email, password: password)
                            // Set selected tab to chat (2) after login
                            tabSelection.selectedTab = 2
                        } label: {
                            Text(authViewModel.isLoading ? "Logging in..." : "Log In")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    isFormValid ?
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "FF8A00"), Color(hex: "FF5100")]),
                                        startPoint: .leading, endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.7)]),
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: isFormValid ? Color(hex: "FF5100").opacity(0.3) : Color.clear, radius: 8, x: 0, y: 5)
                        }
                        .disabled(!isFormValid || authViewModel.isLoading)
                        .padding(.horizontal, 24)
                        .padding(.top, 5)
                        
                        // Register link
                        Button {
                            showRegistration = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("Sign Up")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .font(.footnote)
                        }
                        .padding(.vertical, 20)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                if isFormValid {
                    authViewModel.login(withEmail: email, password: password)
                    // Set selected tab to chat (2) after login
                    tabSelection.selectedTab = 2
                }
            case .none:
                break
            }
        }
        .fullScreenCover(isPresented: $showRegistration) {
            RegistrationView()
                .environmentObject(authViewModel)
                .environmentObject(tabSelection)
        }
    }
    
    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && 
        email.contains("@") &&
        password.count >= 6
    }
}

// Extensions for the new UI elements
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
} 