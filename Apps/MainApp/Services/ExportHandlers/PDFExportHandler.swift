import Foundation
import PDFKit
import UIKit
import CoreGraphics

// MARK: - PDF Export Handler

@available(iOS 14.0, *)
class PDFExportHandler: BaseExportHandler {
    
    override var fileExtension: String {
        return "pdf"
    }
    
    override var mimeType: String {
        return "application/pdf"
    }
    
    override func generateExport(
        data: ProcessedHealthData,
        request: ExportRequest,
        outputPath: URL,
        progressCallback: @escaping (Double) -> Void
    ) async throws {
        
        try validateData(data)
        
        let updateProgress = createProgressTracker(totalSteps: 6, callback: progressCallback)
        
        // Step 1: Prepare PDF configuration
        updateProgress(1)
        let pdfConfig = preparePDFConfiguration(request: request)
        
        // Step 2: Create PDF document
        updateProgress(2)
        let pdfDocument = createPDFDocument(config: pdfConfig)
        
        // Step 3: Add cover page
        updateProgress(3)
        try addCoverPage(to: pdfDocument, data: data, request: request)
        
        // Step 4: Add summary pages
        updateProgress(4)
        try addSummaryPages(to: pdfDocument, data: data, request: request)
        
        // Step 5: Add data visualization pages
        updateProgress(5)
        try addDataVisualizationPages(to: pdfDocument, data: data, request: request)
        
        // Step 6: Save PDF to file
        updateProgress(6)
        try savePDFDocument(pdfDocument, to: outputPath)
    }
    
    override func estimateFileSize(_ data: ProcessedHealthData) -> Int64 {
        // PDF with charts: ~50 bytes per data point + base size
        let baseSize: Int64 = 100000 // 100KB base for PDF structure and images
        let dataSize = Int64(data.dataPoints.count * 50)
        return baseSize + dataSize
    }
    
    // MARK: - PDF Configuration
    
    private struct PDFConfiguration {
        let pageSize: CGSize
        let margins: UIEdgeInsets
        let includeCharts: Bool
        let includeDetailedData: Bool
        let colorScheme: PDFColorScheme
        let fontSize: PDFFontSizes
    }
    
    private struct PDFColorScheme {
        let primary: UIColor
        let secondary: UIColor
        let background: UIColor
        let text: UIColor
        let accent: UIColor
    }
    
    private struct PDFFontSizes {
        let title: CGFloat
        let heading: CGFloat
        let body: CGFloat
        let caption: CGFloat
    }
    
    private func preparePDFConfiguration(request: ExportRequest) -> PDFConfiguration {
        return PDFConfiguration(
            pageSize: CGSize(width: 612, height: 792), // Letter size
            margins: UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72), // 1 inch margins
            includeCharts: request.customOptions["includeCharts"] != "false",
            includeDetailedData: request.customOptions["includeDetailedData"] != "false",
            colorScheme: PDFColorScheme(
                primary: UIColor.systemBlue,
                secondary: UIColor.systemGray,
                background: UIColor.white,
                text: UIColor.black,
                accent: UIColor.systemGreen
            ),
            fontSize: PDFFontSizes(
                title: 24,
                heading: 18,
                body: 12,
                caption: 10
            )
        )
    }
    
    // MARK: - PDF Document Creation
    
    private func createPDFDocument(config: PDFConfiguration) -> PDFDocument {
        return PDFDocument()
    }
    
    private func addCoverPage(to document: PDFDocument, data: ProcessedHealthData, request: ExportRequest) throws {
        let page = createCoverPage(data: data, request: request)
        document.insert(page, at: document.pageCount)
    }
    
    private func createCoverPage(data: ProcessedHealthData, request: ExportRequest) -> PDFPage {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let page = PDFPage()
        
        // Create cover page content
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            UIColor.white.setFill()
            cgContext.fill(pageRect)
            
            // Title
            let titleText = "Health Data Export Report"
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            
            let titleSize = titleText.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (pageRect.width - titleSize.width) / 2,
                y: 150,
                width: titleSize.width,
                height: titleSize.height
            )
            titleText.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Subtitle
            let subtitleText = "Generated by HealthAI 2030"
            let subtitleFont = UIFont.systemFont(ofSize: 16)
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.gray
            ]
            
            let subtitleSize = subtitleText.size(withAttributes: subtitleAttributes)
            let subtitleRect = CGRect(
                x: (pageRect.width - subtitleSize.width) / 2,
                y: 200,
                width: subtitleSize.width,
                height: subtitleSize.height
            )
            subtitleText.draw(in: subtitleRect, withAttributes: subtitleAttributes)
            
            // Export info
            let infoText = createExportInfoText(data: data, request: request)
            let infoFont = UIFont.systemFont(ofSize: 12)
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: infoFont,
                .foregroundColor: UIColor.black
            ]
            
            let infoRect = CGRect(x: 72, y: 300, width: pageRect.width - 144, height: 300)
            infoText.draw(in: infoRect, withAttributes: infoAttributes)
            
            // Footer
            let footerText = "Export Date: \(formatDateForDisplay(Date()))"
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            
            let footerSize = footerText.size(withAttributes: footerAttributes)
            let footerRect = CGRect(
                x: (pageRect.width - footerSize.width) / 2,
                y: pageRect.height - 100,
                width: footerSize.width,
                height: footerSize.height
            )
            footerText.draw(in: footerRect, withAttributes: footerAttributes)
        }
        
        page.setBounds(pageRect, for: .mediaBox)
        return page
    }
    
    private func createExportInfoText(data: ProcessedHealthData, request: ExportRequest) -> String {
        var info = ""
        info += "Export Summary\n\n"
        info += "Format: \(request.format.displayName)\n"
        info += "Date Range: \(formatDateForDisplay(request.dateRange.startDate)) to \(formatDateForDisplay(request.dateRange.endDate))\n"
        info += "Total Records: \(data.summary.totalRecords)\n"
        info += "Data Types: \(data.summary.dataTypeBreakdown.count)\n"
        info += "Sources: \(data.summary.sourceBreakdown.count)\n\n"
        
        if request.privacySettings.anonymizeData {
            info += "⚠️ Data has been anonymized\n"
        }
        if request.privacySettings.excludeSensitiveData {
            info += "⚠️ Sensitive data has been excluded\n"
        }
        
        return info
    }
    
    // MARK: - Summary Pages
    
    private func addSummaryPages(to document: PDFDocument, data: ProcessedHealthData, request: ExportRequest) throws {
        // Add data type summary page
        let summaryPage = createDataTypeSummaryPage(data: data)
        document.insert(summaryPage, at: document.pageCount)
        
        // Add category breakdown page
        let categoryPage = createCategoryBreakdownPage(data: data)
        document.insert(categoryPage, at: document.pageCount)
    }
    
    private func createDataTypeSummaryPage(data: ProcessedHealthData) -> PDFPage {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let page = PDFPage()
        
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            UIColor.white.setFill()
            cgContext.fill(pageRect)
            
            // Title
            let title = "Data Type Summary"
            drawTitle(title, at: CGPoint(x: 72, y: 720), in: cgContext)
            
            // Create table
            let tableData = createDataTypeSummaryTable(data: data)
            drawTable(tableData, startY: 650, in: cgContext, pageRect: pageRect)
        }
        
        page.setBounds(pageRect, for: .mediaBox)
        return page
    }
    
    private func createCategoryBreakdownPage(data: ProcessedHealthData) -> PDFPage {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let page = PDFPage()
        
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            UIColor.white.setFill()
            cgContext.fill(pageRect)
            
            // Title
            let title = "Category Breakdown"
            drawTitle(title, at: CGPoint(x: 72, y: 720), in: cgContext)
            
            // Create category chart
            if let chart = createCategoryChart(data: data, size: CGSize(width: 400, height: 300)) {
                let chartRect = CGRect(x: 106, y: 350, width: 400, height: 300)
                chart.draw(in: chartRect)
            }
        }
        
        page.setBounds(pageRect, for: .mediaBox)
        return page
    }
    
    // MARK: - Data Visualization Pages
    
    private func addDataVisualizationPages(to document: PDFDocument, data: ProcessedHealthData, request: ExportRequest) throws {
        let config = preparePDFConfiguration(request: request)
        
        if config.includeCharts {
            // Group data by category for charts
            let groupedData = Dictionary(grouping: data.dataPoints) { $0.dataType.category }
            
            for (category, points) in groupedData {
                let chartPage = createCategoryChartPage(category: category, dataPoints: points)
                document.insert(chartPage, at: document.pageCount)
            }
        }
        
        if config.includeDetailedData {
            let detailPages = createDetailedDataPages(data: data)
            for page in detailPages {
                document.insert(page, at: document.pageCount)
            }
        }
    }
    
    private func createCategoryChartPage(category: HealthDataCategory, dataPoints: [HealthDataPoint]) -> PDFPage {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let page = PDFPage()
        
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            UIColor.white.setFill()
            cgContext.fill(pageRect)
            
            // Title
            let title = "\(category.rawValue) Data"
            drawTitle(title, at: CGPoint(x: 72, y: 720), in: cgContext)
            
            // Create time series chart for this category
            if let chart = createTimeSeriesChart(dataPoints: dataPoints, size: CGSize(width: 450, height: 300)) {
                let chartRect = CGRect(x: 81, y: 350, width: 450, height: 300)
                chart.draw(in: chartRect)
            }
            
            // Add statistics
            let stats = calculateCategoryStatistics(dataPoints: dataPoints)
            drawStatistics(stats, startY: 300, in: cgContext)
        }
        
        page.setBounds(pageRect, for: .mediaBox)
        return page
    }
    
    private func createDetailedDataPages(data: ProcessedHealthData) -> [PDFPage] {
        var pages: [PDFPage] = []
        let itemsPerPage = 40
        let chunks = data.dataPoints.chunked(into: itemsPerPage)
        
        for (index, chunk) in chunks.enumerated() {
            let page = createDetailedDataPage(dataPoints: chunk, pageNumber: index + 1, totalPages: chunks.count)
            pages.append(page)
        }
        
        return pages
    }
    
    private func createDetailedDataPage(dataPoints: [HealthDataPoint], pageNumber: Int, totalPages: Int) -> PDFPage {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let page = PDFPage()
        
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            UIColor.white.setFill()
            cgContext.fill(pageRect)
            
            // Title
            let title = "Detailed Data (Page \(pageNumber) of \(totalPages))"
            drawTitle(title, at: CGPoint(x: 72, y: 720), in: cgContext)
            
            // Create detailed data table
            let tableData = createDetailedDataTable(dataPoints: dataPoints)
            drawTable(tableData, startY: 680, in: cgContext, pageRect: pageRect)
        }
        
        page.setBounds(pageRect, for: .mediaBox)
        return page
    }
    
    // MARK: - Drawing Helpers
    
    private func drawTitle(_ title: String, at point: CGPoint, in context: CGContext) {
        let titleFont = UIFont.boldSystemFont(ofSize: 18)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        title.draw(at: point, withAttributes: titleAttributes)
    }
    
    private func drawTable(_ data: [[String]], startY: CGFloat, in context: CGContext, pageRect: CGRect) {
        let font = UIFont.systemFont(ofSize: 10)
        let rowHeight: CGFloat = 20
        let columnWidth = (pageRect.width - 144) / CGFloat(data.first?.count ?? 1)
        
        for (rowIndex, row) in data.enumerated() {
            let y = startY - CGFloat(rowIndex) * rowHeight
            
            for (colIndex, cell) in row.enumerated() {
                let x = 72 + CGFloat(colIndex) * columnWidth
                let cellRect = CGRect(x: x, y: y - rowHeight, width: columnWidth, height: rowHeight)
                
                // Draw cell border
                context.setStrokeColor(UIColor.lightGray.cgColor)
                context.setLineWidth(0.5)
                context.stroke(cellRect)
                
                // Draw cell text
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black
                ]
                
                let textRect = cellRect.insetBy(dx: 4, dy: 2)
                cell.draw(in: textRect, withAttributes: attributes)
            }
        }
    }
    
    private func drawStatistics(_ stats: [String: String], startY: CGFloat, in context: CGContext) {
        let font = UIFont.systemFont(ofSize: 12)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        var y = startY
        for (key, value) in stats {
            let text = "\(key): \(value)"
            text.draw(at: CGPoint(x: 72, y: y), withAttributes: attributes)
            y -= 20
        }
    }
    
    // MARK: - Data Processing Helpers
    
    private func createDataTypeSummaryTable(data: ProcessedHealthData) -> [[String]] {
        var table = [["Data Type", "Category", "Count", "Average", "Min", "Max"]]
        
        let grouped = Dictionary(grouping: data.dataPoints) { $0.dataType }
        
        for (dataType, points) in grouped.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            let values = points.map { $0.value }
            let average = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
            let min = values.min() ?? 0
            let max = values.max() ?? 0
            
            table.append([
                dataType.rawValue,
                dataType.category.rawValue,
                String(points.count),
                formatValue(average),
                formatValue(min),
                formatValue(max)
            ])
        }
        
        return table
    }
    
    private func createDetailedDataTable(dataPoints: [HealthDataPoint]) -> [[String]] {
        var table = [["Date", "Data Type", "Value", "Unit", "Source"]]
        
        for point in dataPoints {
            table.append([
                formatDateForDisplay(point.startDate),
                point.dataType.rawValue,
                formatValue(point.value),
                point.unit,
                point.source
            ])
        }
        
        return table
    }
    
    private func calculateCategoryStatistics(dataPoints: [HealthDataPoint]) -> [String: String] {
        let values = dataPoints.map { $0.value }
        let average = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        
        return [
            "Total Records": String(dataPoints.count),
            "Average Value": formatValue(average),
            "Minimum Value": formatValue(values.min() ?? 0),
            "Maximum Value": formatValue(values.max() ?? 0),
            "Date Range": "\(formatDateForDisplay(dataPoints.map { $0.startDate }.min() ?? Date())) - \(formatDateForDisplay(dataPoints.map { $0.endDate }.max() ?? Date()))"
        ]
    }
    
    // MARK: - Chart Creation (Simplified)
    
    private func createCategoryChart(data: ProcessedHealthData, size: CGSize) -> UIImage? {
        // Simplified chart creation - in a real implementation, you'd use Core Graphics or a charting library
        return nil
    }
    
    private func createTimeSeriesChart(dataPoints: [HealthDataPoint], size: CGSize) -> UIImage? {
        // Simplified chart creation - in a real implementation, you'd use Core Graphics or a charting library
        return nil
    }
    
    // MARK: - PDF Saving
    
    private func savePDFDocument(_ document: PDFDocument, to url: URL) throws {
        guard document.write(to: url) else {
            throw ExportError.fileGenerationError("Failed to write PDF document to file")
        }
    }
}

// MARK: - Array Extension

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - PDF Export Options

extension ExportRequest {
    /// Get PDF-specific export options
    var pdfExportOptions: PDFExportOptions {
        return PDFExportOptions(
            includeCharts: customOptions["includeCharts"] != "false",
            includeDetailedData: customOptions["includeDetailedData"] != "false",
            pageSize: customOptions["pageSize"] ?? "letter",
            colorScheme: customOptions["colorScheme"] ?? "default"
        )
    }
}

struct PDFExportOptions {
    let includeCharts: Bool
    let includeDetailedData: Bool
    let pageSize: String
    let colorScheme: String
    
    init(includeCharts: Bool = true, includeDetailedData: Bool = true, pageSize: String = "letter", colorScheme: String = "default") {
        self.includeCharts = includeCharts
        self.includeDetailedData = includeDetailedData
        self.pageSize = pageSize
        self.colorScheme = colorScheme
    }
}