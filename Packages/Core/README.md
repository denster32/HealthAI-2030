# Core Frameworks

This directory contains the consolidated core frameworks for HealthAI-2030.

## Structure

- **HealthAI2030Core**: Core functionality and business logic
- **HealthAI2030UI**: Shared UI components and views
- **HealthAI2030Networking**: Network layer and API clients
- **HealthAI2030Foundation**: Foundation utilities and extensions

## Migration Notes

These frameworks have been consolidated from multiple locations:
- Sources/Features/
- Frameworks/
- Packages/
- Apps/Packages/
- Modules/Core/

All duplicate implementations have been merged, keeping the most complete versions.

## Dependencies

The dependency hierarchy is:
```
HealthAI2030Foundation (no dependencies)
    ↓
HealthAI2030Core (depends on Foundation)
    ↓
HealthAI2030Networking (depends on Core, Foundation)
    ↓
HealthAI2030UI (depends on all above)
```
