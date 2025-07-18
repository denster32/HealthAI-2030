# Notification & Reminder System Documentation

## Overview

The HealthAI 2030 notification and reminder system provides a comprehensive solution for delivering health-related notifications to users. The system supports local notifications, push notifications, user customization, privacy controls, and integration with health data and goals.

## Architecture

### Core Components

- **NotificationManager**: Central manager for all notification operations
- **NotificationSettings**: User preferences and configuration
- **HealthReminder**: Individual reminder instances
- **NotificationRecord**: Historical notification tracking

### Key Features

- **Multi-type Notifications**: Health alerts, reminders, achievements, weekly reports
- **User Customization**: Granular control over notification types and schedules
- **Privacy Controls**: Quiet hours, daily limits, user consent
- **Actionable Notifications**: Interactive buttons for user engagement
- **Health Integration**: Context-aware notifications based on health data

## Notification Types

### 1. Health Alerts

Critical, urgent, and normal health notifications based on real-time health data.

```swift
// Send a critical health alert
try await notificationManager.sendHealthAlert(
    title: "Critical Heart Rate Alert",
    body: "Your heart rate is dangerously high",
    severity: .critical,
    userInfo: ["heartRate": 120]
)
```

**Severity Levels:**
- **Critical**: Life-threatening conditions, emergency notifications
- **Urgent**: Serious health concerns requiring attention
- **Normal**: General health information and updates

### 2. Reminders

Scheduled notifications for health-related activities.

```swift
// Schedule a medication reminder
try await notificationManager.sendReminder(
    title: "Medication Reminder",
    body: "Time to take your medication",
    reminderType: .medication,
    scheduledDate: Date().addingTimeInterval(3600), // 1 hour from now
    userInfo: ["medicationId": "med123"]
)
```

**Reminder Types:**
- `medication`: Medication schedule reminders
- `exercise`: Workout and activity reminders
- `hydration`: Water intake reminders
- `sleep`: Sleep schedule reminders
- `appointment`: Medical appointment reminders
- `healthCheck`: Regular health monitoring reminders
- `mindfulness`: Meditation and wellness reminders

### 3. Achievements

Celebration notifications for goal completions and milestones.

```swift
// Send achievement notification
try await notificationManager.sendAchievement(
    title: "Step Goal Achieved!",
    body: "Congratulations! You've reached your daily step goal",
    achievementType: .stepGoal,
    userInfo: ["steps": 10000, "goal": 8000]
)
```

**Achievement Types:**
- `stepGoal`: Daily step count achievements
- `sleepGoal`: Sleep duration and quality achievements
- `exerciseStreak`: Workout consistency achievements
- `mindfulnessStreak`: Meditation consistency achievements
- `weightGoal`: Weight management achievements
- `healthMilestone`: General health milestones

### 4. Weekly Reports

Periodic health summary notifications.

```swift
// Send weekly health report
try await notificationManager.sendWeeklyReport(
    title: "Weekly Health Report",
    body: "Your health summary for this week is ready",
    reportData: ["avgSteps": 8500, "avgSleep": 7.5]
)
```

## User Settings & Customization

### Notification Preferences

Users can customize which types of notifications they receive:

```swift
var settings = NotificationSettings()
settings.healthAlertsEnabled = true
settings.remindersEnabled = true
settings.achievementsEnabled = false
settings.weeklyReportsEnabled = true
settings.sleepTrackingEnabled = true
settings.medicationRemindersEnabled = true

notificationManager.updateSettings(settings)
```

### Quiet Hours

Configure periods when most notifications are suppressed:

```swift
let quietHours = QuietHours(
    start: TimeOfDay(hour: 22, minute: 0), // 10:00 PM
    end: TimeOfDay(hour: 7, minute: 0)     // 7:00 AM
)

var settings = notificationManager.notificationSettings
settings.quietHours = quietHours
notificationManager.updateSettings(settings)
```

**Quiet Hours Exceptions:**
- Critical health alerts
- Medication reminders
- Emergency notifications

### Daily Limits

Set maximum notifications per day to prevent notification fatigue:

```swift
var settings = notificationManager.notificationSettings
settings.maxNotificationsPerDay = 15
notificationManager.updateSettings(settings)
```

## Notification Actions

### Interactive Buttons

Notifications include actionable buttons for user engagement:

**Health Alerts:**
- View Details: Opens relevant health data
- Call Emergency: Initiates emergency call (critical alerts)
- Schedule Appointment: Opens appointment booking (urgent alerts)

**Reminders:**
- Mark Complete: Records completion
- Snooze: Reschedules for later
- Dismiss: Removes notification

**Achievements:**
- View Achievement: Shows achievement details
- Share: Shares achievement on social media

**Weekly Reports:**
- View Report: Opens detailed report
- Share Report: Shares report with healthcare provider

### Action Handling

```swift
// Handle notification actions
NotificationCenter.default.addObserver(
    forName: NSNotification.Name("NotificationAction"),
    object: nil,
    queue: .main
) { notification in
    guard let userInfo = notification.userInfo,
          let action = userInfo["action"] as? String else { return }
    
    switch action {
    case "VIEW_DETAILS":
        // Navigate to health details
    case "COMPLETE":
        // Mark reminder as complete
    case "SNOOZE":
        // Reschedule reminder
    default:
        break
    }
}
```

## Privacy & Security

### User Consent

- Explicit permission requests for notification access
- Granular control over notification types
- Ability to disable all notifications
- Clear privacy policy integration

### Data Protection

- No sensitive health data in notification content
- Secure storage of notification preferences
- Compliance with health data regulations
- User-controlled data retention

### Quiet Hours Respect

- Automatic suppression during quiet hours
- Exceptions for critical health alerts
- User-configurable quiet hour periods
- Respect for system Do Not Disturb settings

## Integration with Health Data

### Context-Aware Notifications

Notifications are triggered based on real-time health data:

```swift
// Example: Heart rate monitoring
if heartRate > 100 {
    try await notificationManager.sendHealthAlert(
        title: "Elevated Heart Rate",
        body: "Your heart rate is above normal levels",
        severity: .urgent,
        userInfo: ["heartRate": heartRate]
    )
}
```

### Goal Integration

Notifications support health goal tracking:

```swift
// Example: Step goal progress
if steps >= stepGoal * 0.8 {
    try await notificationManager.sendHealthAlert(
        title: "Goal Progress",
        body: "You're 80% to your daily step goal!",
        severity: .normal
    )
}
```

## Testing

### Unit Tests

Comprehensive test coverage for all notification functionality:

```bash
# Run notification tests
swift test --filter NotificationManagerTests
```

### Test Scenarios

- Authorization requests and status checks
- Notification sending for all types
- Settings persistence and updates
- Quiet hours functionality
- Reminder scheduling and cancellation
- Error handling and edge cases

## Best Practices

### Notification Design

1. **Clear and Concise**: Keep titles and messages brief and actionable
2. **Appropriate Severity**: Use correct severity levels for health alerts
3. **Relevant Information**: Include only necessary data in userInfo
4. **Actionable Content**: Provide clear next steps for users

### User Experience

1. **Respect Preferences**: Honor user notification settings
2. **Avoid Spam**: Use daily limits and smart scheduling
3. **Quiet Hours**: Respect user-defined quiet periods
4. **Progressive Disclosure**: Start with essential notifications

### Performance

1. **Efficient Scheduling**: Use appropriate trigger types
2. **Memory Management**: Clean up old notification records
3. **Background Processing**: Handle notifications efficiently
4. **Error Handling**: Graceful degradation when notifications fail

## Troubleshooting

### Common Issues

**Notifications Not Appearing:**
- Check notification permissions
- Verify notification settings are enabled
- Ensure app is not in Do Not Disturb mode
- Check quiet hours configuration

**Reminders Not Scheduling:**
- Verify notification authorization
- Check reminder type settings
- Ensure scheduled date is in the future
- Review daily notification limits

**Actions Not Working:**
- Verify notification categories are registered
- Check action identifier matching
- Ensure proper notification handling setup

### Debug Tools

```swift
// Check notification authorization status
await notificationManager.checkAuthorizationStatus()

// View pending notifications
let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()

// View notification history
let history = notificationManager.notificationHistory
```

## Future Enhancements

### Planned Features

1. **Smart Notifications**: AI-powered notification timing
2. **Location Awareness**: Location-based health reminders
3. **Family Sharing**: Family member health notifications
4. **Healthcare Integration**: Provider notification system
5. **Advanced Analytics**: Notification effectiveness tracking

### API Extensions

1. **Custom Notification Types**: User-defined notification categories
2. **Advanced Scheduling**: Complex recurring patterns
3. **Notification Templates**: Predefined notification formats
4. **A/B Testing**: Notification content optimization

## Support

For technical support or questions about the notification system:

- **Documentation**: This document and inline code comments
- **Unit Tests**: Comprehensive test coverage
- **Code Examples**: Sample implementations in test files
- **Integration Guide**: Step-by-step setup instructions

---

*Last updated: December 2024*
*Version: 1.0* 