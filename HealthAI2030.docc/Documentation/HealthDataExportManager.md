# ``HealthAI2030/HealthDataExportManager``

A service for exporting health data in various formats with encryption and privacy controls.

## Overview

The `HealthDataExportManager` provides a comprehensive solution for exporting health data from HealthKit in multiple formats including JSON, CSV, PDF, and Apple Health format. It includes built-in encryption, privacy controls, and progress tracking.

## Topics

### Essentials
- ``startExport(_:)``
- ``cancelExport()``
- ``getExportStatus(id:)``

### Configuration
- ``ExportRequest``
- ``ExportFormat``
- ``EncryptionSettings``

### Results
- ``ExportResult``
- ``ExportProgress``
- ``ExportError``

## See Also

- ``HealthDataManager``
- ``PrivacyManager``
- ``EncryptionManager`` 