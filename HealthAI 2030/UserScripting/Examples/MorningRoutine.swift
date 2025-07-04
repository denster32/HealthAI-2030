// Example: User automation script for morning routine
let script = "WHEN my_sleep_score < 70 DO set_home_lights(to: \"energize\", at: \"7:00 AM\") AND send_notification(\"Try a morning walk!\")"
if let userScript = DSLParser().parse(script) {
    ScriptingEngine().execute(userScript)
}
