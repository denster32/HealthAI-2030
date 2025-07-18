# Apple Developer Team ID Setup Guide

## Overview
This guide will help you configure your Apple Developer Team ID for the HealthAI 2030 project.

## Finding Your Team ID

### Method 1: Apple Developer Portal
1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Sign in with your Apple ID
3. Navigate to "Membership" section
4. Your Team ID will be displayed (format: ABC123DEF4)

### Method 2: Xcode
1. Open Xcode
2. Go to Xcode → Preferences → Accounts
3. Select your Apple ID
4. Click "Manage Certificates" or view Team details
5. Your Team ID is shown next to your team name

### Method 3: Command Line
```bash
# If you have Xcode command line tools installed:
security find-identity -v -p codesigning
```

## Configuring Team ID in the Project

You need to update the Team ID in the following files:
- `/Configuration/ExportOptions.plist`
- `/Configuration/ExportOptionsMac.plist`
- `/Configuration/ExportOptionsTV.plist`
- `/Configuration/ExportOptionsWatch.plist`

Replace `YOUR_TEAM_ID` with your actual Team ID in each file.

## Example
```xml
<key>teamID</key>
<string>ABC123DEF4</string>
```

## Important Notes
- Team ID is different from your Apple ID
- Team ID is typically a 10-character alphanumeric string
- You must be enrolled in the Apple Developer Program
- The same Team ID should be used across all platform configurations

## Troubleshooting
- If you don't have a Team ID, you need to enroll in the Apple Developer Program
- For free developer accounts, you may have limitations on certain capabilities
- Ensure your certificates and provisioning profiles match your Team ID

## Next Steps
After configuring your Team ID:
1. Update provisioning profiles in Xcode
2. Configure code signing settings
3. Test archive and export functionality