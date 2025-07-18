# Team ID Configuration Setup

## 🚨 CRITICAL: Replace Team ID Before App Store Submission

### Current Status
All export configuration files have been updated with a consistent placeholder: `REPLACE_WITH_YOUR_TEAM_ID`

### Files Requiring Team ID Update
1. `Configuration/ExportOptions.plist` - iOS App Store export
2. `Configuration/ExportOptionsMac.plist` - macOS App Store export  
3. `Configuration/ExportOptionsTV.plist` - tvOS App Store export
4. `Configuration/ExportOptionsWatch.plist` - watchOS App Store export

### How to Find Your Team ID
1. Log in to [Apple Developer Portal](https://developer.apple.com/)
2. Go to **Account** → **Membership**
3. Your **Team ID** is displayed (format: `AB12C3D4E5`)

### How to Update Team ID
Run this command replacing `YOUR_ACTUAL_TEAM_ID` with your Team ID:

```bash
# Navigate to project directory
cd /Users/dennispalucki/Documents/HealthAI-2030

# Replace all instances of placeholder with your actual Team ID
find Configuration -name "*.plist" -exec sed -i '' 's/REPLACE_WITH_YOUR_TEAM_ID/YOUR_ACTUAL_TEAM_ID/g' {} \;
```

### Verification
After updating, verify the changes:
```bash
grep -r "YOUR_ACTUAL_TEAM_ID" Configuration --include="*.plist"
```

### Bundle Identifiers to Verify
Ensure these bundle identifiers match your App Store Connect configuration:
- **iOS**: `com.healthai2030.ios` (in `Configuration/BuildSettings-iOS18.xcconfig`)
- **macOS**: `com.healthai2030.mac` 
- **tvOS**: `com.healthai2030.tv`
- **watchOS**: `com.healthai2030.watch`

### Testing Export Process
After updating Team ID, test the export process:
```bash
# Test iOS export
xcodebuild -exportArchive -archivePath HealthAI2030.xcarchive -exportPath Export -exportOptionsPlist Configuration/ExportOptions.plist
```

### ⚠️ Important Notes
- **Never commit your actual Team ID** to public repositories
- Team ID format is 10 characters (letters and numbers)
- All 4 export configuration files must have the same Team ID
- Export will fail if Team ID doesn't match your provisioning profiles

### Next Steps After Team ID Update
1. ✅ Update all 4 export configuration files
2. ✅ Test archive and export process
3. ✅ Verify bundle identifiers match App Store Connect
4. ✅ Run comprehensive test suite
5. ✅ Proceed with App Store submission

---
*This file can be deleted after Team ID configuration is complete*