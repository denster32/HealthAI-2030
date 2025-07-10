// CustomReportBuilder.swift
// HealthAI 2030 - Agent 6 Analytics
// Builder for custom analytics reports

import Foundation

public struct CustomReportSection {
    public let title: String
    public let content: String
}

public struct CustomReport {
    public let id: UUID
    public let title: String
    public let sections: [CustomReportSection]
    public let created: Date
    public let author: String
}

public class CustomReportBuilder {
    private var sections: [CustomReportSection] = []
    private var title: String = ""
    private var author: String = ""
    
    public init() {}
    
    public func setTitle(_ title: String) -> CustomReportBuilder {
        self.title = title
        return self
    }
    
    public func setAuthor(_ author: String) -> CustomReportBuilder {
        self.author = author
        return self
    }
    
    public func addSection(_ section: CustomReportSection) -> CustomReportBuilder {
        sections.append(section)
        return self
    }
    
    public func build() -> CustomReport {
        return CustomReport(id: UUID(), title: title, sections: sections, created: Date(), author: author)
    }
}
