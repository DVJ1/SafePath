/// Accessible Strings and Semantic Labels for SafePath
class AppStrings {
  static const String appName = 'SafePath';
  static const String appTagline = 'Smart Blind Stick Companion & Caregiver Safety Network';

  // Role selection
  static const String roleUserTitle = 'Visually Impaired User Mode';
  static const String roleUserDesc = 'High contrast interface, large touch targets, voice guidance, fall detection, and emergency SOS button.';
  static const String roleCaregiverTitle = 'Caregiver Monitor Mode';
  static const String roleCaregiverDesc = 'Live safety status, real-time GPS location tracking, emergency alert notification, and instant response tools.';

  // Sensor states
  static const String stickConnected = 'Smart Stick Connected';
  static const String stickSimulated = 'Simulation Mode Active';
  static const String stickDisconnected = 'Smart Stick Disconnected';
  static const String stickReconnecting = 'Reconnecting to Stick...';

  static const String obstacleClear = 'Path Clear';
  static const String obstacleClose = 'Obstacle Detected Ahead!';
  static const String obstacleImminent = 'Danger: Obstacle Very Close!';

  static const String surfaceDry = 'Surface Normal / Dry';
  static const String surfaceWet = 'Caution: Water / Puddle Detected';
  static const String surfacePothole = 'Warning: Steep Drop or Pothole!';
  static const String surfaceMud = 'Caution: Mud / Wet Surface';

  static const String fallNormal = 'Orientation Normal';
  static const String fallDetectedAlert = 'Fall Detected! Emergency countdown active!';

  // SOS and Emergencies
  static const String sosButtonLabel = 'EMERGENCY SOS';
  static const String sosButtonHint = 'Double tap or hold to trigger immediate emergency alert';
  static const String sosCancelLabel = 'Cancel False Alarm';
  static const String sosCountdownText = 'Emergency will trigger in {seconds} seconds. Tap cancel if you are safe.';

  // Emergency States
  static const String statusTriggered = 'Emergency Triggered';
  static const String statusSent = 'Alert Sent to Caregivers';
  static const String statusAck = 'Acknowledged by Caregiver';
  static const String statusResponding = 'Caregiver En Route / Responding';
  static const String statusAssisted = 'Assistance Coordinated';
  static const String statusResolved = 'Emergency Resolved & Safe';
  static const String statusCancelled = 'False Alarm Cancelled';
}
