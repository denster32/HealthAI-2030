// Example: User automation script for travel mode
let script = "WHEN location == 'travel' DO send_notification(\"Enable travel health mode\") AND adjust_sleep_goal(6.0)"
if let userScript = DSLParser().parse(script) {
    ScriptingEngine().execute(userScript)
}
