import SwiftUI

@main
struct HealthAI2030iOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("HealthAI 2030")
                    .font(.largeTitle)
                    .padding()
                
                Text("Health Monitoring Dashboard")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // Basic dashboard placeholder
                VStack(spacing: 20) {
                    DashboardCard(title: "Heart Rate", value: "72 BPM", color: .red)
                    DashboardCard(title: "Steps", value: "8,432", color: .blue)
                    DashboardCard(title: "Sleep", value: "7h 23m", color: .purple)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("HealthAI")
        }
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            Spacer()
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: 3)
                )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    ContentView()
}