// Example: User automation script for bedtime routine
let script = "WHEN my_activity_level > 8000 DO set_home_lights(to: \"dim\", at: \"10:00 PM\") AND play_meditation_audio(\"calm_night\")"
if let userScript = DSLParser().parse(script) {
    ScriptingEngine().execute(userScript)
}
