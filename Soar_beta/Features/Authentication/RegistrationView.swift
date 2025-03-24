import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var tabSelection: TabSelection
    
    @State private var email = ""
    @State private var fullname = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case fullname, email, password, confirmPassword
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
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .padding(.bottom, 10)
                        
                        Text("Create your account")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Please enter your details")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 25) {
                        // Form container
                        VStack(spacing: 18) {
                            // Full Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.leading, 3)
                                
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(Color(hex: "0A5BC3"))
                                        .frame(width: 20)
                                    
                                    TextField("", text: $fullname)
                                        .placeholder(when: fullname.isEmpty) {
                                            Text("Enter your full name").foregroundColor(Color(hex: "0A5BC3").opacity(0.5))
                                        }
                                        .textContentType(.name)
                                        .focused($focusedField, equals: .fullname)
                                        .foregroundColor(Color(hex: "0A5BC3"))
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 4)
                            }
                            
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
                                        .textContentType(.newPassword)
                                        .focused($focusedField, equals: .password)
                                        .foregroundColor(Color(hex: "0A5BC3"))
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 4)
                            }
                            
                            // Confirm Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.leading, 3)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(Color(hex: "0A5BC3"))
                                        .frame(width: 20)
                                    
                                    SecureField("", text: $confirmPassword)
                                        .placeholder(when: confirmPassword.isEmpty) {
                                            Text("Confirm your password").foregroundColor(Color(hex: "0A5BC3").opacity(0.5))
                                        }
                                        .textContentType(.newPassword)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .foregroundColor(Color(hex: "0A5BC3"))
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        
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
                        
                        // Register button
                        Button {
                            authViewModel.register(withEmail: email, password: password, fullname: fullname)
                            // Set selected tab to chat (2) after registration
                            tabSelection.selectedTab = 2
                        } label: {
                            Text(authViewModel.isLoading ? "Creating account..." : "Create Account")
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
                        
                        // Login link
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("Log In")
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
        .navigationBarHidden(true)
        .onSubmit {
            switch focusedField {
            case .fullname:
                focusedField = .email
            case .email:
                focusedField = .password
            case .password:
                focusedField = .confirmPassword
            case .confirmPassword:
                if isFormValid {
                    authViewModel.register(withEmail: email, password: password, fullname: fullname)
                    // Set selected tab to chat (2) after registration
                    tabSelection.selectedTab = 2
                }
            case .none:
                break
            }
        }
    }
    
    var isFormValid: Bool {
        !fullname.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty && 
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword
    }
} 