# HealthAI 2030 Accessibility Verification Checklist

## VoiceOver Testing
- [ ] All interactive elements have descriptive labels
- [ ] Navigation order follows logical sequence
- [ ] Dynamic content updates are announced
- [ ] Images and icons have meaningful descriptions
- [ ] Custom gestures have alternative activation methods

## Switch Control Testing
- [ ] All controls are focusable and selectable
- [ ] No focus traps or infinite loops
- [ ] Complex controls have simplified alternatives
- [ ] Time-based interactions can be paused/extended

## Visual Accessibility
- [ ] Text scales properly with Dynamic Type (up to XXXL)
- [ ] Color contrast meets WCAG 2.1 AA standards (4.5:1)
- [ ] No information conveyed by color alone
- [ ] Dark/Light mode support works correctly
- [ ] Reduced Motion setting is respected

## Component-Specific Checks

### HeartRateDisplay
- [ ] Updates announce frequency is reasonable
- [ ] Value format is clear when spoken

### SleepStageIndicator  
- [ ] Stage changes are announced
- [ ] Visual indicators have text equivalents

### MoodSelector
- [ ] Button states are clearly indicated
- [ ] Selection changes are announced
- [ ] Touch targets meet minimum size (44x44pt)

### HealthMetricCard
- [ ] Title and value are combined logically
- [ ] Units are clearly indicated

## Reporting Guidelines
1. For each issue found:
   - Take screenshot
   - Note component and exact issue  
   - Record VoiceOver/Switch Control behavior
   - Suggest specific fixes
2. Report to Analytics with tag "accessibility_issue"