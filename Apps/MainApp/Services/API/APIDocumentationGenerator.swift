import Foundation
import SwiftUI

/// Protocol defining the requirements for API documentation generation
protocol APIDocumentationGeneratorProtocol {
    func generateDocumentation(for endpoint: APIEndpoint) async throws -> EndpointDocumentation
    func generateSDKDocumentation(for language: ProgrammingLanguage) async throws -> SDKDocumentation
    func generateInteractiveExamples(for endpoint: APIEndpoint) async throws -> [InteractiveExample]
    func exportDocumentation(format: DocumentationFormat) async throws -> DocumentationExport
}

/// Structure representing an API endpoint
struct APIEndpoint: Codable, Identifiable {
    let id: String
    let path: String
    let method: HTTPMethod
    let description: String
    let parameters: [APIParameter]
    let requestBody: RequestBodySchema?
    let responses: [APIResponseSchema]
    let authentication: AuthenticationRequirement
    let rateLimit: RateLimitInfo
    let tags: [String]
    
    init(path: String, method: HTTPMethod, description: String, parameters: [APIParameter] = [], requestBody: RequestBodySchema? = nil, responses: [APIResponseSchema] = [], authentication: AuthenticationRequirement = .required, rateLimit: RateLimitInfo = RateLimitInfo(), tags: [String] = []) {
        self.id = UUID().uuidString
        self.path = path
        self.method = method
        self.description = description
        self.parameters = parameters
        self.requestBody = requestBody
        self.responses = responses
        self.authentication = authentication
        self.rateLimit = rateLimit
        self.tags = tags
    }
}

/// Structure representing API parameter
struct APIParameter: Codable, Identifiable {
    let id: String
    let name: String
    let type: ParameterType
    let location: ParameterLocation
    let description: String
    let required: Bool
    let defaultValue: String?
    let example: String?
    
    init(name: String, type: ParameterType, location: ParameterLocation, description: String, required: Bool = false, defaultValue: String? = nil, example: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.location = location
        self.description = description
        self.required = required
        self.defaultValue = defaultValue
        self.example = example
    }
}

/// Structure representing request body schema
struct RequestBodySchema: Codable, Identifiable {
    let id: String
    let contentType: String
    let schema: JSONSchema
    let required: Bool
    let description: String
    
    init(contentType: String, schema: JSONSchema, required: Bool = true, description: String = "") {
        self.id = UUID().uuidString
        self.contentType = contentType
        self.schema = schema
        self.required = required
        self.description = description
    }
}

/// Structure representing API response schema
struct APIResponseSchema: Codable, Identifiable {
    let id: String
    let statusCode: Int
    let description: String
    let contentType: String
    let schema: JSONSchema?
    let examples: [ResponseExample]
    
    init(statusCode: Int, description: String, contentType: String = "application/json", schema: JSONSchema? = nil, examples: [ResponseExample] = []) {
        self.id = UUID().uuidString
        self.statusCode = statusCode
        self.description = description
        self.contentType = contentType
        self.schema = schema
        self.examples = examples
    }
}

/// Structure representing JSON schema
struct JSONSchema: Codable {
    let type: String
    let properties: [String: JSONSchemaProperty]
    let required: [String]
    let description: String?
    
    init(type: String, properties: [String: JSONSchemaProperty] = [:], required: [String] = [], description: String? = nil) {
        self.type = type
        self.properties = properties
        self.required = required
        self.description = description
    }
}

/// Structure representing JSON schema property
struct JSONSchemaProperty: Codable {
    let type: String
    let description: String?
    let example: String?
    let format: String?
    
    init(type: String, description: String? = nil, example: String? = nil, format: String? = nil) {
        self.type = type
        self.description = description
        self.example = example
        self.format = format
    }
}

/// Structure representing response example
struct ResponseExample: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let value: String
    
    init(name: String, description: String, value: String) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.value = value
    }
}

/// Structure representing endpoint documentation
struct EndpointDocumentation: Codable, Identifiable {
    let id: String
    let endpoint: APIEndpoint
    let markdown: String
    let html: String
    let examples: [InteractiveExample]
    let generatedAt: Date
    
    init(endpoint: APIEndpoint, markdown: String, html: String, examples: [InteractiveExample], generatedAt: Date = Date()) {
        self.id = UUID().uuidString
        self.endpoint = endpoint
        self.markdown = markdown
        self.html = html
        self.examples = examples
        self.generatedAt = generatedAt
    }
}

/// Structure representing SDK documentation
struct SDKDocumentation: Codable, Identifiable {
    let id: String
    let language: ProgrammingLanguage
    let installationGuide: String
    let quickStartGuide: String
    let apiReference: String
    let examples: [CodeExample]
    let generatedAt: Date
    
    init(language: ProgrammingLanguage, installationGuide: String, quickStartGuide: String, apiReference: String, examples: [CodeExample], generatedAt: Date = Date()) {
        self.id = UUID().uuidString
        self.language = language
        self.installationGuide = installationGuide
        self.quickStartGuide = quickStartGuide
        self.apiReference = apiReference
        self.examples = examples
        self.generatedAt = generatedAt
    }
}

/// Structure representing interactive example
struct InteractiveExample: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let request: ExampleRequest
    let response: ExampleResponse
    let codeSnippets: [CodeSnippet]
    
    init(title: String, description: String, request: ExampleRequest, response: ExampleResponse, codeSnippets: [CodeSnippet]) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.request = request
        self.response = response
        self.codeSnippets = codeSnippets
    }
}

/// Structure representing example request
struct ExampleRequest: Codable {
    let method: HTTPMethod
    let url: String
    let headers: [String: String]
    let body: String?
    
    init(method: HTTPMethod, url: String, headers: [String: String] = [:], body: String? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}

/// Structure representing example response
struct ExampleResponse: Codable {
    let statusCode: Int
    let headers: [String: String]
    let body: String
    
    init(statusCode: Int, headers: [String: String] = [:], body: String) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

/// Structure representing code snippet
struct CodeSnippet: Codable, Identifiable {
    let id: String
    let language: ProgrammingLanguage
    let title: String
    let code: String
    let description: String
    
    init(language: ProgrammingLanguage, title: String, code: String, description: String) {
        self.id = UUID().uuidString
        self.language = language
        self.title = title
        self.code = code
        self.description = description
    }
}

/// Structure representing code example
struct CodeExample: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let code: String
    let language: ProgrammingLanguage
    
    init(title: String, description: String, code: String, language: ProgrammingLanguage) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.code = code
        self.language = language
    }
}

/// Structure representing documentation export
struct DocumentationExport: Codable, Identifiable {
    let id: String
    let format: DocumentationFormat
    let content: Data
    let filename: String
    let generatedAt: Date
    
    init(format: DocumentationFormat, content: Data, filename: String, generatedAt: Date = Date()) {
        self.id = UUID().uuidString
        self.format = format
        self.content = content
        self.filename = filename
        self.generatedAt = generatedAt
    }
}

/// Structure representing authentication requirement
struct AuthenticationRequirement: Codable {
    let required: Bool
    let type: String
    let description: String
    
    init(required: Bool = true, type: String = "API Key", description: String = "API key in X-API-Key header") {
        self.required = required
        self.type = type
        self.description = description
    }
}

/// Structure representing rate limit information
struct RateLimitInfo: Codable {
    let requestsPerHour: Int
    let requestsPerDay: Int
    let description: String
    
    init(requestsPerHour: Int = 1000, requestsPerDay: Int = 24000, description: String = "Rate limits apply per API key") {
        self.requestsPerHour = requestsPerHour
        self.requestsPerDay = requestsPerDay
        self.description = description
    }
}

/// Enum representing parameter types
enum ParameterType: String, Codable, CaseIterable {
    case string = "string"
    case integer = "integer"
    case number = "number"
    case boolean = "boolean"
    case array = "array"
    case object = "object"
}

/// Enum representing parameter locations
enum ParameterLocation: String, Codable, CaseIterable {
    case query = "query"
    case path = "path"
    case header = "header"
    case body = "body"
}

/// Enum representing programming languages
enum ProgrammingLanguage: String, Codable, CaseIterable {
    case swift = "Swift"
    case python = "Python"
    case javascript = "JavaScript"
    case java = "Java"
    case csharp = "C#"
    case php = "PHP"
    case ruby = "Ruby"
    case go = "Go"
}

/// Enum representing documentation formats
enum DocumentationFormat: String, Codable, CaseIterable {
    case markdown = "Markdown"
    case html = "HTML"
    case pdf = "PDF"
    case json = "JSON"
    case yaml = "YAML"
}

/// Actor responsible for generating API documentation
actor APIDocumentationGenerator: APIDocumentationGeneratorProtocol {
    private let templateEngine: DocumentationTemplateEngine
    private let codeGenerator: CodeExampleGenerator
    private let logger: Logger
    private let endpoints: [APIEndpoint]
    
    init() {
        self.templateEngine = DocumentationTemplateEngine()
        self.codeGenerator = CodeExampleGenerator()
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "DocumentationGenerator")
        self.endpoints = Self.loadDefaultEndpoints()
    }
    
    /// Generates documentation for a specific endpoint
    /// - Parameter endpoint: The API endpoint to document
    /// - Returns: EndpointDocumentation object
    func generateDocumentation(for endpoint: APIEndpoint) async throws -> EndpointDocumentation {
        logger.info("Generating documentation for endpoint: \(endpoint.method.rawValue) \(endpoint.path)")
        
        // Generate markdown documentation
        let markdown = try await templateEngine.generateMarkdown(for: endpoint)
        
        // Generate HTML documentation
        let html = try await templateEngine.generateHTML(for: endpoint)
        
        // Generate interactive examples
        let examples = try await generateInteractiveExamples(for: endpoint)
        
        let documentation = EndpointDocumentation(
            endpoint: endpoint,
            markdown: markdown,
            html: html,
            examples: examples
        )
        
        logger.info("Generated documentation for endpoint: \(endpoint.path)")
        return documentation
    }
    
    /// Generates SDK documentation for a specific programming language
    /// - Parameter language: The programming language to generate SDK docs for
    /// - Returns: SDKDocumentation object
    func generateSDKDocumentation(for language: ProgrammingLanguage) async throws -> SDKDocumentation {
        logger.info("Generating SDK documentation for language: \(language.rawValue)")
        
        // Generate installation guide
        let installationGuide = try await templateEngine.generateInstallationGuide(for: language)
        
        // Generate quick start guide
        let quickStartGuide = try await templateEngine.generateQuickStartGuide(for: language)
        
        // Generate API reference
        let apiReference = try await templateEngine.generateAPIReference(for: language, endpoints: endpoints)
        
        // Generate code examples
        let examples = try await codeGenerator.generateExamples(for: language, endpoints: endpoints)
        
        let sdkDocumentation = SDKDocumentation(
            language: language,
            installationGuide: installationGuide,
            quickStartGuide: quickStartGuide,
            apiReference: apiReference,
            examples: examples
        )
        
        logger.info("Generated SDK documentation for language: \(language.rawValue)")
        return sdkDocumentation
    }
    
    /// Generates interactive examples for an endpoint
    /// - Parameter endpoint: The API endpoint to generate examples for
    /// - Returns: Array of InteractiveExample objects
    func generateInteractiveExamples(for endpoint: APIEndpoint) async throws -> [InteractiveExample] {
        logger.info("Generating interactive examples for endpoint: \(endpoint.path)")
        
        var examples: [InteractiveExample] = []
        
        // Generate basic example
        let basicExample = try await generateBasicExample(for: endpoint)
        examples.append(basicExample)
        
        // Generate authenticated example
        if endpoint.authentication.required {
            let authExample = try await generateAuthenticatedExample(for: endpoint)
            examples.append(authExample)
        }
        
        // Generate error example
        let errorExample = try await generateErrorExample(for: endpoint)
        examples.append(errorExample)
        
        logger.info("Generated \(examples.count) interactive examples for endpoint: \(endpoint.path)")
        return examples
    }
    
    /// Exports documentation in a specific format
    /// - Parameter format: The format to export documentation in
    /// - Returns: DocumentationExport object
    func exportDocumentation(format: DocumentationFormat) async throws -> DocumentationExport {
        logger.info("Exporting documentation in format: \(format.rawValue)")
        
        var content: Data
        var filename: String
        
        switch format {
        case .markdown:
            content = try await generateMarkdownExport()
            filename = "healthai2030_api_documentation.md"
        case .html:
            content = try await generateHTMLExport()
            filename = "healthai2030_api_documentation.html"
        case .pdf:
            content = try await generatePDFExport()
            filename = "healthai2030_api_documentation.pdf"
        case .json:
            content = try await generateJSONExport()
            filename = "healthai2030_api_documentation.json"
        case .yaml:
            content = try await generateYAMLExport()
            filename = "healthai2030_api_documentation.yaml"
        }
        
        let export = DocumentationExport(
            format: format,
            content: content,
            filename: filename
        )
        
        logger.info("Exported documentation in \(format.rawValue) format")
        return export
    }
    
    /// Generates a basic example for an endpoint
    private func generateBasicExample(for endpoint: APIEndpoint) async throws -> InteractiveExample {
        let request = ExampleRequest(
            method: endpoint.method,
            url: "https://api.healthai2030.com\(endpoint.path)",
            headers: ["Content-Type": "application/json"]
        )
        
        let response = ExampleResponse(
            statusCode: 200,
            headers: ["Content-Type": "application/json"],
            body: generateSampleResponse(for: endpoint)
        )
        
        let codeSnippets = try await codeGenerator.generateCodeSnippets(for: endpoint, language: .javascript)
        
        return InteractiveExample(
            title: "Basic Request",
            description: "A basic request to the \(endpoint.path) endpoint",
            request: request,
            response: response,
            codeSnippets: codeSnippets
        )
    }
    
    /// Generates an authenticated example for an endpoint
    private func generateAuthenticatedExample(for endpoint: APIEndpoint) async throws -> InteractiveExample {
        let request = ExampleRequest(
            method: endpoint.method,
            url: "https://api.healthai2030.com\(endpoint.path)",
            headers: [
                "Content-Type": "application/json",
                "X-API-Key": "your_api_key_here"
            ]
        )
        
        let response = ExampleResponse(
            statusCode: 200,
            headers: ["Content-Type": "application/json"],
            body: generateSampleResponse(for: endpoint)
        )
        
        let codeSnippets = try await codeGenerator.generateCodeSnippets(for: endpoint, language: .python)
        
        return InteractiveExample(
            title: "Authenticated Request",
            description: "An authenticated request to the \(endpoint.path) endpoint",
            request: request,
            response: response,
            codeSnippets: codeSnippets
        )
    }
    
    /// Generates an error example for an endpoint
    private func generateErrorExample(for endpoint: APIEndpoint) async throws -> InteractiveExample {
        let request = ExampleRequest(
            method: endpoint.method,
            url: "https://api.healthai2030.com\(endpoint.path)",
            headers: ["Content-Type": "application/json"]
        )
        
        let response = ExampleResponse(
            statusCode: 401,
            headers: ["Content-Type": "application/json"],
            body: """
            {
                "error": "Authentication failed",
                "status_code": 401,
                "message": "Missing or invalid API key"
            }
            """
        )
        
        let codeSnippets = try await codeGenerator.generateErrorHandlingSnippets(for: endpoint, language: .swift)
        
        return InteractiveExample(
            title: "Error Handling",
            description: "Example of error handling for the \(endpoint.path) endpoint",
            request: request,
            response: response,
            codeSnippets: codeSnippets
        )
    }
    
    /// Generates sample response for an endpoint
    private func generateSampleResponse(for endpoint: APIEndpoint) -> String {
        // In a real implementation, this would generate based on the response schema
        return """
        {
            "status": "success",
            "data": {
                "id": "sample_id",
                "created_at": "2025-01-01T00:00:00Z"
            }
        }
        """
    }
    
    /// Generates markdown export
    private func generateMarkdownExport() async throws -> Data {
        var markdown = "# HealthAI 2030 API Documentation\n\n"
        markdown += "Generated on: \(Date().formatted())\n\n"
        
        for endpoint in endpoints {
            let endpointDoc = try await generateDocumentation(for: endpoint)
            markdown += endpointDoc.markdown + "\n\n"
        }
        
        return markdown.data(using: .utf8) ?? Data()
    }
    
    /// Generates HTML export
    private func generateHTMLExport() async throws -> Data {
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>HealthAI 2030 API Documentation</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; }
                .endpoint { border: 1px solid #ddd; margin: 20px 0; padding: 20px; }
                .method { font-weight: bold; color: #007cba; }
                .path { font-family: monospace; background: #f5f5f5; padding: 5px; }
            </style>
        </head>
        <body>
            <h1>HealthAI 2030 API Documentation</h1>
            <p>Generated on: \(Date().formatted())</p>
        """
        
        for endpoint in endpoints {
            let endpointDoc = try await generateDocumentation(for: endpoint)
            html += endpointDoc.html
        }
        
        html += "</body></html>"
        return html.data(using: .utf8) ?? Data()
    }
    
    /// Generates PDF export
    private func generatePDFExport() async throws -> Data {
        // In a real implementation, this would use a PDF generation library
        let markdown = try await generateMarkdownExport()
        let markdownString = String(data: markdown, encoding: .utf8) ?? ""
        
        // For now, return the markdown as PDF content (would be converted in real implementation)
        return markdown
    }
    
    /// Generates JSON export
    private func generateJSONExport() async throws -> Data {
        let documentation = DocumentationExportData(
            title: "HealthAI 2030 API Documentation",
            version: "1.0.0",
            generatedAt: Date(),
            endpoints: endpoints
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(documentation)
    }
    
    /// Generates YAML export
    private func generateYAMLExport() async throws -> Data {
        // In a real implementation, this would use a YAML library
        let jsonData = try await generateJSONExport()
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        
        // For now, return JSON as YAML content (would be converted in real implementation)
        return jsonData
    }
    
    /// Loads default API endpoints
    private static func loadDefaultEndpoints() -> [APIEndpoint] {
        return [
            APIEndpoint(
                path: "/api/v1/health",
                method: .GET,
                description: "Get health data for the authenticated user",
                parameters: [
                    APIParameter(name: "start_date", type: .string, location: .query, description: "Start date for data range", example: "2025-01-01"),
                    APIParameter(name: "end_date", type: .string, location: .query, description: "End date for data range", example: "2025-01-31")
                ],
                responses: [
                    APIResponseSchema(statusCode: 200, description: "Success", examples: [
                        ResponseExample(name: "Success Response", description: "Health data retrieved successfully", value: "{\"data\": [...], \"total\": 100}")
                    ]),
                    APIResponseSchema(statusCode: 401, description: "Unauthorized"),
                    APIResponseSchema(statusCode: 429, description: "Rate limit exceeded")
                ],
                tags: ["Health Data"]
            ),
            APIEndpoint(
                path: "/api/v1/analytics",
                method: .POST,
                description: "Submit analytics data for processing",
                requestBody: RequestBodySchema(
                    contentType: "application/json",
                    schema: JSONSchema(
                        type: "object",
                        properties: [
                            "event_type": JSONSchemaProperty(type: "string", description: "Type of analytics event"),
                            "data": JSONSchemaProperty(type: "object", description: "Event data")
                        ],
                        required: ["event_type", "data"]
                    )
                ),
                responses: [
                    APIResponseSchema(statusCode: 201, description: "Analytics data submitted successfully"),
                    APIResponseSchema(statusCode: 400, description: "Invalid request data"),
                    APIResponseSchema(statusCode: 401, description: "Unauthorized")
                ],
                tags: ["Analytics"]
            )
        ]
    }
}

/// Structure representing documentation export data
struct DocumentationExportData: Codable {
    let title: String
    let version: String
    let generatedAt: Date
    let endpoints: [APIEndpoint]
}

/// Class managing documentation template engine
class DocumentationTemplateEngine {
    private let logger: Logger
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "TemplateEngine")
    }
    
    /// Generates markdown documentation for an endpoint
    func generateMarkdown(for endpoint: APIEndpoint) async throws -> String {
        var markdown = "## \(endpoint.method.rawValue) \(endpoint.path)\n\n"
        markdown += "\(endpoint.description)\n\n"
        
        if !endpoint.parameters.isEmpty {
            markdown += "### Parameters\n\n"
            markdown += "| Name | Type | Location | Required | Description |\n"
            markdown += "|------|------|----------|----------|-------------|\n"
            
            for param in endpoint.parameters {
                markdown += "| \(param.name) | \(param.type.rawValue) | \(param.location.rawValue) | \(param.required ? "Yes" : "No") | \(param.description) |\n"
            }
            markdown += "\n"
        }
        
        if let requestBody = endpoint.requestBody {
            markdown += "### Request Body\n\n"
            markdown += "**Content-Type:** \(requestBody.contentType)\n\n"
            markdown += "```json\n\(generateJSONSchemaExample(requestBody.schema))\n```\n\n"
        }
        
        markdown += "### Responses\n\n"
        for response in endpoint.responses {
            markdown += "#### \(response.statusCode) - \(response.description)\n\n"
            if let schema = response.schema {
                markdown += "```json\n\(generateJSONSchemaExample(schema))\n```\n\n"
            }
        }
        
        return markdown
    }
    
    /// Generates HTML documentation for an endpoint
    func generateHTML(for endpoint: APIEndpoint) async throws -> String {
        var html = "<div class='endpoint'>"
        html += "<h2><span class='method'>\(endpoint.method.rawValue)</span> <span class='path'>\(endpoint.path)</span></h2>"
        html += "<p>\(endpoint.description)</p>"
        
        if !endpoint.parameters.isEmpty {
            html += "<h3>Parameters</h3><table><tr><th>Name</th><th>Type</th><th>Location</th><th>Required</th><th>Description</th></tr>"
            for param in endpoint.parameters {
                html += "<tr><td>\(param.name)</td><td>\(param.type.rawValue)</td><td>\(param.location.rawValue)</td><td>\(param.required ? "Yes" : "No")</td><td>\(param.description)</td></tr>"
            }
            html += "</table>"
        }
        
        html += "</div>"
        return html
    }
    
    /// Generates installation guide for a programming language
    func generateInstallationGuide(for language: ProgrammingLanguage) async throws -> String {
        switch language {
        case .swift:
            return """
            # Swift SDK Installation
            
            ## Using Swift Package Manager
            
            Add the following dependency to your `Package.swift`:
            
            ```swift
            dependencies: [
                .package(url: "https://github.com/healthai2030/swift-sdk.git", from: "1.0.0")
            ]
            ```
            
            ## Using CocoaPods
            
            Add the following to your `Podfile`:
            
            ```ruby
            pod 'HealthAI2030SDK'
            ```
            """
        case .python:
            return """
            # Python SDK Installation
            
            ## Using pip
            
            ```bash
            pip install healthai2030-sdk
            ```
            
            ## Using conda
            
            ```bash
            conda install -c healthai2030 healthai2030-sdk
            ```
            """
        default:
            return "Installation guide for \(language.rawValue) is coming soon."
        }
    }
    
    /// Generates quick start guide for a programming language
    func generateQuickStartGuide(for language: ProgrammingLanguage) async throws -> String {
        switch language {
        case .swift:
            return """
            # Swift SDK Quick Start
            
            ```swift
            import HealthAI2030SDK
            
            let client = HealthAI2030Client(apiKey: "your_api_key")
            
            // Get health data
            let healthData = try await client.getHealthData()
            print("Health data: \(healthData)")
            ```
            """
        case .python:
            return """
            # Python SDK Quick Start
            
            ```python
            from healthai2030 import Client
            
            client = Client(api_key="your_api_key")
            
            # Get health data
            health_data = client.get_health_data()
            print(f"Health data: {health_data}")
            ```
            """
        default:
            return "Quick start guide for \(language.rawValue) is coming soon."
        }
    }
    
    /// Generates API reference for a programming language
    func generateAPIReference(for language: ProgrammingLanguage, endpoints: [APIEndpoint]) async throws -> String {
        var reference = "# \(language.rawValue) SDK API Reference\n\n"
        
        for endpoint in endpoints {
            reference += "## \(endpoint.method.rawValue) \(endpoint.path)\n\n"
            reference += "\(endpoint.description)\n\n"
        }
        
        return reference
    }
    
    /// Generates JSON schema example
    private func generateJSONSchemaExample(_ schema: JSONSchema) -> String {
        // In a real implementation, this would generate a proper JSON example
        return """
        {
            "example": "value"
        }
        """
    }
}

/// Class managing code example generation
class CodeExampleGenerator {
    private let logger: Logger
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "CodeGenerator")
    }
    
    /// Generates code examples for a programming language and endpoints
    func generateExamples(for language: ProgrammingLanguage, endpoints: [APIEndpoint]) async throws -> [CodeExample] {
        var examples: [CodeExample] = []
        
        for endpoint in endpoints {
            let example = try await generateExample(for: endpoint, language: language)
            examples.append(example)
        }
        
        return examples
    }
    
    /// Generates code snippets for an endpoint
    func generateCodeSnippets(for endpoint: APIEndpoint, language: ProgrammingLanguage) async throws -> [CodeSnippet] {
        var snippets: [CodeSnippet] = []
        
        switch language {
        case .javascript:
            snippets.append(CodeSnippet(
                language: language,
                title: "JavaScript (Fetch)",
                code: generateJavaScriptSnippet(endpoint),
                description: "Using the Fetch API"
            ))
        case .python:
            snippets.append(CodeSnippet(
                language: language,
                title: "Python (requests)",
                code: generatePythonSnippet(endpoint),
                description: "Using the requests library"
            ))
        case .swift:
            snippets.append(CodeSnippet(
                language: language,
                title: "Swift (URLSession)",
                code: generateSwiftSnippet(endpoint),
                description: "Using URLSession"
            ))
        default:
            snippets.append(CodeSnippet(
                language: language,
                title: "Generic HTTP",
                code: generateGenericSnippet(endpoint),
                description: "Generic HTTP request"
            ))
        }
        
        return snippets
    }
    
    /// Generates error handling code snippets
    func generateErrorHandlingSnippets(for endpoint: APIEndpoint, language: ProgrammingLanguage) async throws -> [CodeSnippet] {
        var snippets: [CodeSnippet] = []
        
        switch language {
        case .swift:
            snippets.append(CodeSnippet(
                language: language,
                title: "Swift Error Handling",
                code: """
                do {
                    let response = try await client.request(endpoint: "\(endpoint.path)")
                    // Handle success
                } catch {
                    // Handle error
                    print("Error: \\(error)")
                }
                """,
                description: "Error handling in Swift"
            ))
        default:
            snippets.append(CodeSnippet(
                language: language,
                title: "Error Handling",
                code: "// Error handling code for \(language.rawValue)",
                description: "Error handling example"
            ))
        }
        
        return snippets
    }
    
    /// Generates an example for an endpoint and language
    private func generateExample(for endpoint: APIEndpoint, language: ProgrammingLanguage) async throws -> CodeExample {
        let code = try await generateCodeSnippet(for: endpoint, language: language)
        
        return CodeExample(
            title: "\(endpoint.method.rawValue) \(endpoint.path)",
            description: endpoint.description,
            code: code,
            language: language
        )
    }
    
    /// Generates a code snippet for an endpoint and language
    private func generateCodeSnippet(for endpoint: APIEndpoint, language: ProgrammingLanguage) async throws -> String {
        switch language {
        case .javascript:
            return generateJavaScriptSnippet(endpoint)
        case .python:
            return generatePythonSnippet(endpoint)
        case .swift:
            return generateSwiftSnippet(endpoint)
        default:
            return generateGenericSnippet(endpoint)
        }
    }
    
    /// Generates JavaScript snippet
    private func generateJavaScriptSnippet(_ endpoint: APIEndpoint) -> String {
        return """
        fetch('https://api.healthai2030.com\(endpoint.path)', {
            method: '\(endpoint.method.rawValue)',
            headers: {
                'Content-Type': 'application/json',
                'X-API-Key': 'your_api_key'
            }
        })
        .then(response => response.json())
        .then(data => console.log(data));
        """
    }
    
    /// Generates Python snippet
    private func generatePythonSnippet(_ endpoint: APIEndpoint) -> String {
        return """
        import requests
        
        response = requests.\(endpoint.method.rawValue.lowercased())(
            'https://api.healthai2030.com\(endpoint.path)',
            headers={
                'Content-Type': 'application/json',
                'X-API-Key': 'your_api_key'
            }
        )
        data = response.json()
        print(data)
        """
    }
    
    /// Generates Swift snippet
    private func generateSwiftSnippet(_ endpoint: APIEndpoint) -> String {
        return """
        let url = URL(string: "https://api.healthai2030.com\(endpoint.path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "\(endpoint.method.rawValue)"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("your_api_key", forHTTPHeaderField: "X-API-Key")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data)
                print(json)
            }
        }.resume()
        """
    }
    
    /// Generates generic snippet
    private func generateGenericSnippet(_ endpoint: APIEndpoint) -> String {
        return """
        \(endpoint.method.rawValue) https://api.healthai2030.com\(endpoint.path)
        Content-Type: application/json
        X-API-Key: your_api_key
        """
    }
}

/// Custom error types for documentation generation
enum DocumentationError: Error {
    case templateGenerationFailed(String)
    case codeGenerationFailed(String)
    case exportFailed(String)
    case invalidEndpoint(String)
}

extension APIDocumentationGenerator {
    /// Configuration for documentation generation
    struct Configuration {
        let includeExamples: Bool
        let includeSDKs: [ProgrammingLanguage]
        let exportFormats: [DocumentationFormat]
        let autoUpdate: Bool
        
        static let `default` = Configuration(
            includeExamples: true,
            includeSDKs: [.swift, .python, .javascript],
            exportFormats: [.markdown, .html, .json],
            autoUpdate: true
        )
    }
    
    /// Regenerates all documentation
    func regenerateAllDocumentation() async throws {
        logger.info("Regenerating all documentation")
        
        for endpoint in endpoints {
            _ = try await generateDocumentation(for: endpoint)
        }
        
        for language in ProgrammingLanguage.allCases {
            _ = try await generateSDKDocumentation(for: language)
        }
        
        logger.info("Completed regeneration of all documentation")
    }
} 