import SwiftUI

struct CoverageDetailView: View {
    @ObservedObject var testingManager: ComprehensiveTestingManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedFile: String?
    @State private var showingFileDetails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Overall Coverage Summary
                    overallCoverageSection
                    
                    // Coverage Breakdown by Type
                    coverageBreakdownSection
                    
                    // File Coverage
                    fileCoverageSection
                    
                    // Coverage Trends
                    coverageTrendsSection
                    
                    // Coverage Recommendations
                    coverageRecommendationsSection
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("Coverage Analysis", comment: "Coverage analysis navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(NSLocalizedString("Done", comment: "Done button")) {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingFileDetails) {
                if let fileName = selectedFile {
                    FileCoverageDetailView(fileName: fileName)
                }
            }
        }
    }
    
    // MARK: - Overall Coverage Section
    private var overallCoverageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Overall Coverage", comment: "Overall coverage section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(String(format: "%.1f", testingManager.testCoverage.coveragePercentage))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(coverageColor)
                    Text(NSLocalizedString("Code Coverage", comment: "Code coverage label"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                CircularProgressView(progress: testingManager.testCoverage.coveragePercentage / 100.0)
                    .frame(width: 80, height: 80)
            }
            
            // Coverage Stats
            HStack(spacing: 20) {
                CoverageStatItem(
                    title: NSLocalizedString("Lines", comment: "Lines label"),
                    covered: testingManager.testCoverage.coveredLines,
                    total: testingManager.testCoverage.totalLines
                )
                
                CoverageStatItem(
                    title: NSLocalizedString("Functions", comment: "Functions label"),
                    covered: testingManager.testCoverage.coveredFunctions,
                    total: testingManager.testCoverage.totalFunctions
                )
                
                CoverageStatItem(
                    title: NSLocalizedString("Classes", comment: "Classes label"),
                    covered: testingManager.testCoverage.coveredClasses,
                    total: testingManager.testCoverage.totalClasses
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Coverage Breakdown Section
    private var coverageBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Coverage Breakdown", comment: "Coverage breakdown section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                CoverageBreakdownRow(
                    title: NSLocalizedString("Function Coverage", comment: "Function coverage"),
                    percentage: testingManager.testCoverage.functionCoveragePercentage,
                    icon: "function",
                    description: NSLocalizedString("Percentage of functions with test coverage", comment: "Function coverage description")
                )
                
                CoverageBreakdownRow(
                    title: NSLocalizedString("Class Coverage", comment: "Class coverage"),
                    percentage: testingManager.testCoverage.classCoveragePercentage,
                    icon: "cube.fill",
                    description: NSLocalizedString("Percentage of classes with test coverage", comment: "Class coverage description")
                )
                
                CoverageBreakdownRow(
                    title: NSLocalizedString("Branch Coverage", comment: "Branch coverage"),
                    percentage: 87.5, // Simulated value
                    icon: "arrow.branch",
                    description: NSLocalizedString("Percentage of code branches covered", comment: "Branch coverage description")
                )
                
                CoverageBreakdownRow(
                    title: NSLocalizedString("Statement Coverage", comment: "Statement coverage"),
                    percentage: 94.2, // Simulated value
                    icon: "text.alignleft",
                    description: NSLocalizedString("Percentage of statements executed", comment: "Statement coverage description")
                )
            }
        }
    }
    
    // MARK: - File Coverage Section
    private var fileCoverageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("File Coverage", comment: "File coverage section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(sampleFileCoverage, id: \.fileName) { fileCoverage in
                    FileCoverageRow(fileCoverage: fileCoverage) {
                        selectedFile = fileCoverage.fileName
                        showingFileDetails = true
                    }
                }
            }
        }
    }
    
    // MARK: - Coverage Trends Section
    private var coverageTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Coverage Trends", comment: "Coverage trends section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TrendRow(
                    period: "Last 7 days",
                    change: "+2.3%",
                    isPositive: true
                )
                
                TrendRow(
                    period: "Last 30 days",
                    change: "+5.1%",
                    isPositive: true
                )
                
                TrendRow(
                    period: "Last 90 days",
                    change: "+8.7%",
                    isPositive: true
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Coverage Recommendations Section
    private var coverageRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Coverage Recommendations", comment: "Coverage recommendations section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                RecommendationCard(
                    title: NSLocalizedString("Add Unit Tests", comment: "Add unit tests recommendation"),
                    description: NSLocalizedString("Focus on testing core business logic and data models", comment: "Unit tests recommendation description"),
                    priority: .high,
                    icon: "plus.circle.fill"
                )
                
                RecommendationCard(
                    title: NSLocalizedString("Improve Edge Case Coverage", comment: "Edge case coverage recommendation"),
                    description: NSLocalizedString("Add tests for error conditions and boundary cases", comment: "Edge case recommendation description"),
                    priority: .medium,
                    icon: "exclamationmark.triangle.fill"
                )
                
                RecommendationCard(
                    title: NSLocalizedString("Integration Test Coverage", comment: "Integration test recommendation"),
                    description: NSLocalizedString("Increase coverage for component interactions", comment: "Integration test recommendation description"),
                    priority: .medium,
                    icon: "link.circle.fill"
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var coverageColor: Color {
        let coverage = testingManager.testCoverage.coveragePercentage
        if coverage >= 90 { return .green }
        else if coverage >= 80 { return .orange }
        else { return .red }
    }
    
    private var sampleFileCoverage: [FileCoverage] {
        [
            FileCoverage(fileName: "HealthDataManager.swift", coverage: 95.2, lines: 150, coveredLines: 143),
            FileCoverage(fileName: "AnalyticsEngine.swift", coverage: 87.8, lines: 200, coveredLines: 176),
            FileCoverage(fileName: "CoreDataManager.swift", coverage: 92.1, lines: 120, coveredLines: 111),
            FileCoverage(fileName: "NotificationManager.swift", coverage: 78.5, lines: 80, coveredLines: 63),
            FileCoverage(fileName: "SecurityManager.swift", coverage: 96.3, lines: 180, coveredLines: 173)
        ]
    }
}

// MARK: - Supporting Models
struct FileCoverage {
    let fileName: String
    let coverage: Double
    let lines: Int
    let coveredLines: Int
}

// MARK: - Supporting Views
struct CoverageStatItem: View {
    let title: String
    let covered: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(covered)/\(total)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct CoverageBreakdownRow: View {
    let title: String
    let percentage: Double
    let icon: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", percentage))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(coverageColor)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var coverageColor: Color {
        if percentage >= 90 { return .green }
        else if percentage >= 80 { return .orange }
        else { return .red }
    }
}

struct FileCoverageRow: View {
    let fileCoverage: FileCoverage
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fileCoverage.fileName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(fileCoverage.coveredLines)/\(fileCoverage.lines) lines")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(String(format: "%.1f", fileCoverage.coverage))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(coverageColor)
                    
                    ProgressView(value: fileCoverage.coverage, total: 100.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: coverageColor))
                        .frame(width: 60)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var coverageColor: Color {
        if fileCoverage.coverage >= 90 { return .green }
        else if fileCoverage.coverage >= 80 { return .orange }
        else { return .red }
    }
}

struct TrendRow: View {
    let period: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            Text(period)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .foregroundColor(isPositive ? .green : .red)
                    .font(.caption)
                
                Text(change)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RecommendationCard: View {
    let title: String
    let description: String
    let priority: Priority
    let icon: String
    
    enum Priority {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(priority.color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(priority.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priority.color.opacity(0.1))
                        .foregroundColor(priority.color)
                        .cornerRadius(4)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct FileCoverageDetailView: View {
    let fileName: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Detailed coverage information for \(fileName)")
                        .font(.headline)
                        .padding()
                }
            }
            .navigationTitle("File Coverage")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    CoverageDetailView(testingManager: ComprehensiveTestingManager())
} 