import SwiftUI

struct EnvironmentalHealthView: View {
    @StateObject private var analyticsEngine = AnalyticsEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Environmental Health")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 8)
            
            if let forecast = analyticsEngine.environmentalImpactForecast {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Environmental Impact Forecast")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "leaf.arrow.triangle.circlepath")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading) {
                            Text("Overall Impact: \(forecast.confidence > 0.7 ? "Low" : "Moderate")")
                                .fontWeight(.semibold)
                            Text("Confidence: \(Int(forecast.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommendations")
                            .font(.headline)
                        
                        if forecast.energyImpact < -0.05 {
                            RecommendationRow(
                                icon: "bolt.slash.fill",
                                title: "Low Energy Alert",
                                description: "High pollen and poor air quality may reduce your energy levels today. Consider an indoor workout.",
                                color: .orange
                            )
                        }
                        
                        if forecast.moodImpact < -0.05 {
                            RecommendationRow(
                                icon: "moon.stars.fill",
                                title: "Mood Advisory",
                                description: "Elevated noise levels may affect your mood. Try some noise-cancelling headphones or a quiet activity.",
                                color: .blue
                            )
                        }
                        
                        if forecast.cognitiveImpact < -0.05 {
                            RecommendationRow(
                                icon: "brain.head.profile",
                                title: "Cognitive Performance",
                                description: "Air quality may impact your focus. Take short breaks and stay hydrated.",
                                color: .purple
                            )
                        }
                        
                        if forecast.energyImpact >= -0.05 && forecast.moodImpact >= -0.05 && forecast.cognitiveImpact >= -0.05 {
                            Text("No significant environmental impacts detected. Enjoy your day!")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                
            } else {
                Text("Analyzing environmental data...")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            analyticsEngine.refreshAnalytics()
        }
    }
}

struct RecommendationRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct EnvironmentalHealthView_Previews: PreviewProvider {
    static var previews: some View {
        EnvironmentalHealthView()
    }
}