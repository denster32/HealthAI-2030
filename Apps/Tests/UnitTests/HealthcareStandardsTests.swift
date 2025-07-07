import XCTest
@testable import HealthAI2030Core

final class HealthcareStandardsTests: XCTestCase {
    let standards = HealthcareStandardsManager.shared
    
    func testCreateFHIRResource() {
        let data = ["name": "John Doe", "age": 30]
        let resource = standards.createFHIRResource(type: "Patient", id: "patient1", data: data)
        XCTAssertEqual(resource.resourceType, "Patient")
        XCTAssertEqual(resource.id, "patient1")
        XCTAssertEqual(resource.data["name"] as? String, "John Doe")
    }
    
    func testValidateFHIRResource() {
        let validResource = HealthcareStandardsManager.FHIRResource(resourceType: "Patient", id: "patient1", data: [:])
        let invalidResource = HealthcareStandardsManager.FHIRResource(resourceType: "", id: "", data: [:])
        
        XCTAssertTrue(standards.validateFHIRResource(validResource))
        XCTAssertFalse(standards.validateFHIRResource(invalidResource))
    }
    
    func testConvertToFHIR() {
        let data = Data([1,2,3])
        let fhirResource = standards.convertToFHIR(data: data)
        XCTAssertNotNil(fhirResource)
        XCTAssertEqual(fhirResource?.resourceType, "Patient")
    }
    
    func testProcessDICOMImage() {
        let imageData = Data([1,2,3,4,5])
        let processed = standards.processDICOMImage(imageData)
        XCTAssertNotNil(processed)
    }
    
    func testExtractDICOMMetadata() {
        let imageData = Data([1,2,3,4,5])
        let metadata = standards.extractDICOMMetadata(imageData)
        XCTAssertEqual(metadata["patientName"] as? String, "John Doe")
        XCTAssertEqual(metadata["studyDate"] as? String, "20240115")
        XCTAssertEqual(metadata["modality"] as? String, "CT")
        XCTAssertEqual(metadata["imageSize"] as? String, "512x512")
    }
    
    func testValidateDICOMImage() {
        XCTAssertTrue(standards.validateDICOMImage(Data([1,2,3])))
        XCTAssertFalse(standards.validateDICOMImage(Data()))
    }
    
    func testAllExchangeProtocols() {
        let protocols: [HealthcareStandardsManager.ExchangeProtocol] = [
            .hl7v2,
            .hl7v3,
            .fhir,
            .dicom,
            .xds
        ]
        
        for protocol in protocols {
            let success = standards.exchangeData(protocol: protocol, data: Data([1,2,3]), destination: "test")
            XCTAssertTrue(success)
        }
    }
    
    func testReceiveData() {
        let protocols: [HealthcareStandardsManager.ExchangeProtocol] = [.hl7v2, .fhir, .dicom]
        
        for protocol in protocols {
            let data = standards.receiveData(protocol: protocol, source: "test")
            XCTAssertNotNil(data)
        }
    }
    
    func testValidateHL7Compliance() {
        let compliant = standards.validateHL7Compliance(data: Data([1,2,3]))
        XCTAssertTrue(compliant)
    }
    
    func testValidateDICOMCompliance() {
        let compliant = standards.validateDICOMCompliance(data: Data([1,2,3]))
        XCTAssertTrue(compliant)
    }
    
    func testValidateFHIRCompliance() {
        let resource = HealthcareStandardsManager.FHIRResource(resourceType: "Patient", id: "patient1", data: [:])
        let compliant = standards.validateFHIRCompliance(resource: resource)
        XCTAssertTrue(compliant)
    }
    
    func testHL7Integration() {
        let success = standards.testHL7Integration()
        XCTAssertTrue(success)
    }
    
    func testDICOMIntegration() {
        let success = standards.testDICOMIntegration()
        XCTAssertTrue(success)
    }
    
    func testFHIRIntegration() {
        let success = standards.testFHIRIntegration()
        XCTAssertTrue(success)
    }
    
    func testGenerateComplianceReport() {
        let report = standards.generateComplianceReport()
        XCTAssertEqual(report["hl7Compliant"] as? Bool, true)
        XCTAssertEqual(report["dicomCompliant"] as? Bool, true)
        XCTAssertEqual(report["fhirCompliant"] as? Bool, true)
        XCTAssertEqual(report["lastValidated"] as? String, "2024-01-15")
        XCTAssertEqual(report["certificationStatus"] as? String, "certified")
    }
    
    func testGetCertificationStatus() {
        let status = standards.getCertificationStatus()
        XCTAssertEqual(status, "certified")
    }
    
    func testExportStandardsDocumentation() {
        let documentation = standards.exportStandardsDocumentation()
        XCTAssertNotNil(documentation)
    }
} 