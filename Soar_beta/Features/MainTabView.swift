import SwiftUI

class TabSelection: ObservableObject {
    @Published var selectedTab = 2 // Default to chat tab
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var tabSelection: TabSelection
    
    var body: some View {
        TabView(selection: $tabSelection.selectedTab) {
            NavigationView {
                HomeTabView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)
            
            NavigationView {
                TripsTabView()
            }
            .tabItem {
                Label("Trips", systemImage: "airplane")
            }
            .tag(1)
            
            // Center tab - Chat
            NavigationView {
                ChatView()
            }
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
            .tag(2)
            
            NavigationView {
                FlightsTabView()
            }
            .tabItem {
                Label("Flights", systemImage: "ticket")
            }
            .tag(3)
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(4)
        }
        .onAppear {
            // Ensure chat tab is selected when view appears after login/registration
            tabSelection.selectedTab = 2
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile header
            VStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text(authViewModel.currentUser?.fullname ?? "User")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(authViewModel.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Sign out button
            Button(action: {
                showSignOutConfirmation = true
            }) {
                Text("Sign Out")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .navigationTitle("Profile")
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
} 