import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var tabSelection = TabSelection()
    @State private var showQuickChat = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if authViewModel.userSession == nil {
                    LoginView()
                } else if !authViewModel.hasCompletedOnboarding {
                    // Show onboarding if the user hasn't completed it yet
                    OnboardingView()
                } else {
                    MainTabView()
                        .environmentObject(tabSelection)
                        .sheet(isPresented: $showQuickChat) {
                            NavigationView {
                                ChatView()
                                    .navigationBarItems(trailing: Button("Done") {
                                        showQuickChat = false
                                    })
                            }
                        }
                }
            }
            .overlay {
                if authViewModel.isLoading {
                    LoadingView()
                }
            }
            
            // Floating action button for quick chat access - only show when not on chat tab
            // and when user is logged in and has completed onboarding
            if authViewModel.userSession != nil && 
               authViewModel.hasCompletedOnboarding &&
               !showQuickChat && 
               tabSelection.selectedTab != 2 &&
               tabSelection.selectedTab != 4 {
                Button(action: {
                    showQuickChat = true
                }) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.purple)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 80)
                .transition(.scale)
            }
        }
        .onAppear {
            // Check onboarding status when view appears
            if let userId = authViewModel.userSession?.uid {
                authViewModel.checkOnboardingStatus(uid: userId)
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.7)
                .ignoresSafeArea()
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle())
        }
    }
} 