/* THIS CODDE HAS THREE WHEEL AND TWO WHEEL 
 * ============================================================
 *  2WD Robot Car — Multi-Mode Firmware
 *  Architecture: Mode Table (function pointer dispatch)
 * ============================================================
 *
 *  ADDING A NEW MODE — only 3 steps:
 *    1. Write void initMyMode() and void tickMyMode()
 *    2. Add an entry to the MODES[] table at the bottom of setup
 *    3. Add the mode name to the MODE_NAMES[] array
 * ──────────────────────────────────────────────────────────────
 *  CURRENT MODES
 *    0  BLE       Manual Flutter control
 *    1  CARD      Sentry2 card detection
 *    2  LINE      IR line following
 *    3  FACE      Sentry2 face following (person tracking)
 *
 *  MODE SWITCHING (via BLE)
 *    'M'        Cycle to next mode
 *    '0'–'3'    Jump directly to mode by number
 *    'S'        Emergency stop (works in ALL modes)
 *
 * ──────────────────────────────────────────────────────────────
 *  HARDWARE
 *    PCA9685 0x47  CH2=L_DIR CH3=L_PWM CH6=R_DIR CH7=R_PWM CH8=SERVO
 *    Sentry2 0x60  (card mode + face mode)
 *    HM-10 BLE     UART 9600 baud
 *    IR sensors    LEFT=A0  MIDDLE=A1  RIGHT=A2
 *
 * ──────────────────────────────────────────────────────────────
 *  BLE COMMANDS (BLE mode only unless noted)
 *    'F' forward        'B' backward       'S' stop (all modes)
 *    'L' trim left 5°   'R' trim right 5°  'C' centre wheels
 *    'l' drive left     'r' drive right    'U' U-turn
 *    'a' speed up       'd' speed down
 *    'M' next mode      '0'-'3' jump to mode
 *
 * ──────────────────────────────────────────────────────────────
 *  TUNING CONSTANTS
 *    S_STEP_BLE    5     degrees per L/R trim tap
 *    S_MAX_L       45    left servo limit
 *    S_MAX_R       135   right servo limit
 *    RAMP_STEP     50    speed ramp per 40ms tick
 *    DUR_LEFT      1800  card-mode left turn duration (ms)
 *    DUR_RIGHT     1800  card-mode right turn duration (ms)
 *    DUR_AROUND    3500  card-mode U-turn duration (ms)
 *    FACE_KP       2.0   face steering proportional gain
 *    FACE_DEAD_ZONE 8    ±units from centre before steering activates
 *    FACE_CLOSE_H  55    height % above this = too close → stop
 *    FACE_FAR_H    15    height % below this = too far  → speed up
 * ============================================================
 */

#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>
#include <Sentry.h>

// ──────────────────────────────────────────────────────────────────
//  PCA9685
// ──────────────────────────────────────────────────────────────────
Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x47);

#define LEFT_DIR_CH   2
#define LEFT_PWM_CH   3
#define RIGHT_DIR_CH  6
#define RIGHT_PWM_CH  7
#define SERVO_CH      8

#define DIR_FWD  4095
#define DIR_REV  0

// ──────────────────────────────────────────────────────────────────
//  SERVO
// ──────────────────────────────────────────────────────────────────
#define SERVO_MIN_PULSE  150
#define SERVO_MAX_PULSE  600
#define S_CENTRE         90
#define S_MAX_L          45
#define S_MAX_R          135
#define S_STEP_BLE       5
#define S_STEP_CAM       1

int current_angle = S_CENTRE;
int target_angle  = S_CENTRE;

// ──────────────────────────────────────────────────────────────────
//  SPEED
// ──────────────────────────────────────────────────────────────────
const int RAMP_STEP  = 50;
const int SPEED_MIN  = 800;
const int SPEED_MAX  = 2555;
const int SPD_40     = 1000;
const int SPD_60     = 1200;
const int SPD_NORMAL = 1800;
const int SPD_80     = 2500;

int normalSpeed   = SPD_NORMAL;
int current_speed = 0;
int target_speed  = 0;

// ──────────────────────────────────────────────────────────────────
//  ENUMS
// ──────────────────────────────────────────────────────────────────
enum DriveState { STOPPED, FWD, REV };
DriveState driveState = STOPPED;
//added drives
enum DriveConfig {
  DRIVE_2WD,
  DRIVE_3WD
};

DriveConfig driveConfig = DRIVE_2WD;

// ──────────────────────────────────────────────────────────────────
//  MODE TABLE
// ──────────────────────────────────────────────────────────────────
struct ModeEntry {
  const char* name;   // Printed on mode switch for debugging
  void (*init)();     // Called once when entering this mode
  void (*tick)();     // Called every loop() iteration
};

// Forward declarations — implementations follow below
void initBLE();   void tickBLE();
void initCard();  void tickCard();
void initLine();  void tickLine();
void initFace();  void tickFace();

// THE MODE TABLE — add new rows here to register new modes
const ModeEntry MODES[] = {
  { "BLE Manual",      initBLE,  tickBLE  },   // index 0
  { "Card Detection",  initCard, tickCard },   // index 1
  { "Line Following",  initLine, tickLine },   // index 2
  { "Face Following",  initFace, tickFace },   // index 3
};
const int MODE_COUNT = sizeof(MODES) / sizeof(MODES[0]);

int currentMode = 0;   // Active mode index

// Switch to a specific mode index — clamps, resets, calls init
void switchMode(int idx) {
  idx = constrain(idx, 0, MODE_COUNT - 1);
  // Clean shutdown of current mode
  driveState    = STOPPED;
  target_speed  = 0;
  current_speed = 0;
  rearStop();        // defined below
  // Activate new mode
  currentMode = idx;
  Serial.print(">> MODE "); Serial.print(idx);
  Serial.print(": "); Serial.println(MODES[idx].name);
  MODES[idx].init();
}

// Cycle to next mode (wraps around)
void nextMode() {
  switchMode((currentMode + 1) % MODE_COUNT);
}


// ══════════════════════════════════════════════════════════════════
//  SHARED HARDWARE HELPERS
//  (called by all modes — never change these)
// ══════════════════════════════════════════════════════════════════

void setServoAngle(int angle) {
  angle = constrain(angle, S_MAX_L, S_MAX_R);
  int pulse = map(angle, 0, 180, SERVO_MIN_PULSE, SERVO_MAX_PULSE);
  pwm.setPWM(SERVO_CH, 0, pulse);
}

void steerCentre() {
  current_angle = S_CENTRE;
  target_angle  = S_CENTRE;
  setServoAngle(S_CENTRE);
}

void steerNudgeLeft() {
  current_angle = constrain(current_angle - S_STEP_BLE, S_MAX_L, S_MAX_R);
  target_angle  = current_angle;
  setServoAngle(current_angle);
  Serial.print("SteerTrim="); Serial.println(current_angle);
}

void steerNudgeRight() {
  current_angle = constrain(current_angle + S_STEP_BLE, S_MAX_L, S_MAX_R);
  target_angle  = current_angle;
  setServoAngle(current_angle);
  Serial.print("SteerTrim="); Serial.println(current_angle);
}

void rearStop() {
  pwm.setPWM(LEFT_PWM_CH,  0, 0);
  pwm.setPWM(RIGHT_PWM_CH, 0, 0);
}

void setMotors(int lDir, int rDir, int lSpd, int rSpd) {
  pwm.setPWM(LEFT_DIR_CH,  0, lDir);
  pwm.setPWM(LEFT_PWM_CH,  0, lSpd);
  pwm.setPWM(RIGHT_DIR_CH, 0, rDir);
  pwm.setPWM(RIGHT_PWM_CH, 0, rSpd);
}

// Standard ramp helper — call each tick, updates current_speed toward target_speed
void rampSpeed() {
  if (current_speed != target_speed) {
    int delta = (target_speed > current_speed) ? RAMP_STEP : -RAMP_STEP;
    current_speed += delta;
    if (abs(target_speed - current_speed) < RAMP_STEP) current_speed = target_speed;
  }
}

// Apply equal speed to both motors in current driveState direction 2wheel drive 3 wheel drive change possible 
void applyDrive(int spd) {

  if (driveConfig == DRIVE_2WD) {
    if      (driveState == FWD) setMotors(DIR_FWD, DIR_FWD, spd, spd);
    else if (driveState == REV) setMotors(DIR_REV, DIR_REV, spd, spd);
    else rearStop();
  }

  else if (driveConfig == DRIVE_3WD) {
    if      (driveState == FWD) setMotors(DIR_FWD, DIR_FWD, spd, 0);
    else if (driveState == REV) setMotors(DIR_REV, DIR_REV, spd, 0);
    else rearStop();
  }

}

// Differential drive with servo angle bias (used by camera + face modes)
// Outer wheel gets a speed boost, inner wheel gets a speed cut
void applyDifferential(int spd) {
  float dev     = current_angle - 90.0f;
  float abs_dev = abs(dev);
  float outer   = 0.30f * (abs_dev / 45.0f);
  float inner   = 0.20f * (abs_dev / 45.0f);
  float lMult   = 1.0f, rMult = 1.0f;
  if      (dev > 0) { rMult += outer; lMult -= inner; }
  else if (dev < 0) { lMult += outer; rMult -= inner; }
  int lPWM = constrain((int)(spd * lMult), 0, 4095);
  int rPWM = constrain((int)(spd * rMult), 0, 4095);
  if (spd > 0) setMotors(DIR_FWD, DIR_FWD, lPWM, rPWM);
  else         rearStop();
}

// Smooth servo ramp toward target_angle (camera/face modes)
void rampServo() {
  if (current_angle != target_angle) {
    int delta = (target_angle > current_angle) ? S_STEP_CAM : -S_STEP_CAM;
    current_angle += delta;
    if (abs(target_angle - current_angle) <= S_STEP_CAM * 2) current_angle = target_angle;
    setServoAngle(current_angle);
  }
}


// ══════════════════════════════════════════════════════════════════
//  MODE 0 — BLE MANUAL
// ══════════════════════════════════════════════════════════════════

void initBLE() {
  steerCentre();
  Serial.println("BLE: Ready for commands");
}

// BLE motion commands (called from loop's serial handler)
void bleCmdForward()    { steerCentre(); driveState = FWD; target_speed = normalSpeed; }
void bleCmdBackward()   { steerCentre(); driveState = REV; target_speed = normalSpeed; }
void bleCmdStop()       { driveState = STOPPED; target_speed = 0; }
void bleCmdCentre()     { steerCentre(); }
void bleCmdDriveLeft()  { current_angle = S_MAX_L; target_angle = S_MAX_L;
                          setServoAngle(S_MAX_L); driveState = FWD; target_speed = normalSpeed; }
void bleCmdDriveRight() { current_angle = S_MAX_R; target_angle = S_MAX_R;
                          setServoAngle(S_MAX_R); driveState = FWD; target_speed = normalSpeed; }
void bleCmdUTurn() {
  setServoAngle(S_MAX_L);
  current_speed = normalSpeed;
  setMotors(DIR_FWD, DIR_FWD, normalSpeed, normalSpeed);
  delay(900);          // ← TUNE for your car's turning radius
  rearStop();
  current_speed = 0; target_speed = 0; driveState = STOPPED;
  steerCentre();
  Serial.println("U-Turn done");
}
void bleCmdSpeedUp()   { normalSpeed = min(normalSpeed + 200, SPEED_MAX);
                         if (driveState != STOPPED) target_speed = normalSpeed;
                         Serial.print("Speed="); Serial.println(normalSpeed); }
void bleCmdSpeedDown() { normalSpeed = max(normalSpeed - 200, SPEED_MIN);
                         if (driveState != STOPPED) target_speed = normalSpeed;
                         Serial.print("Speed="); Serial.println(normalSpeed); }

void tickBLE() {
  rampSpeed();
  applyDrive(current_speed);
}


// ══════════════════════════════════════════════════════════════════
//  MODE 1 — SENTRY2 CARD DETECTION
// ══════════════════════════════════════════════════════════════════
Sengo2 sengo2(0x60);

#define CARD_FORWARD  1
#define CARD_LEFT     2
#define CARD_RIGHT    3
#define CARD_AROUND   4
#define CARD_STOP     5
#define CARD_SPD40    8
#define CARD_SPD60    9
#define CARD_SPD80    10

const unsigned long DUR_LEFT   = 1800;
const unsigned long DUR_RIGHT  = 1800;
const unsigned long DUR_AROUND = 3500;

int  cardLastLabel = CARD_STOP;
bool cardInTurn    = false;
unsigned long cardTurnStart = 0;

void initCard() {
  sengo2.VisionBegin(Sengo2::kVisionCard);
  cardLastLabel = CARD_STOP;
  cardInTurn    = false;
  steerCentre();
  Serial.println("Card: Scanning...");
}

void tickCard() {
  // Read sensor
  int num = sengo2.GetValue(Sengo2::kVisionCard, kStatus);
  if (num > 0) {
    int det = sengo2.GetValue(Sengo2::kVisionCard, kLabel, 1);
    if (det > 0) {
      cardLastLabel = det;
      cardInTurn    = false;
      Serial.print("Card: "); Serial.println(det);
    }
  }

  // Map label to targets
  switch (cardLastLabel) {
    case CARD_STOP:    target_angle = S_CENTRE; target_speed = 0;           break;
    case CARD_FORWARD: target_angle = S_CENTRE; target_speed = normalSpeed; break;
    case CARD_SPD40:   target_angle = S_CENTRE; target_speed = SPD_40;      break;
    case CARD_SPD60:   target_angle = S_CENTRE; target_speed = SPD_60;      break;
    case CARD_SPD80:   target_angle = S_CENTRE; target_speed = SPD_80;      break;
    case CARD_LEFT:
      target_angle = 60; target_speed = normalSpeed;
      if (!cardInTurn) { cardInTurn = true; cardTurnStart = millis(); }
      break;
    case CARD_RIGHT:
      target_angle = 120; target_speed = normalSpeed;
      if (!cardInTurn) { cardInTurn = true; cardTurnStart = millis(); }
      break;
    case CARD_AROUND:
      target_angle = 135; target_speed = SPD_60;
      if (!cardInTurn) { cardInTurn = true; cardTurnStart = millis(); }
      break;
    default: target_angle = S_CENTRE; target_speed = 0; break;
  }

  // Turn timeout
  if (cardInTurn) {
    unsigned long dur = 0;
    if (cardLastLabel == CARD_LEFT)   dur = DUR_LEFT;
    if (cardLastLabel == CARD_RIGHT)  dur = DUR_RIGHT;
    if (cardLastLabel == CARD_AROUND) dur = DUR_AROUND;
    if (dur > 0 && (millis() - cardTurnStart) >= dur) {
      target_speed = 0; target_angle = S_CENTRE;
      cardInTurn = false;
      delay(400);
    }
  }

  rampServo();
  rampSpeed();
  applyDifferential(current_speed);
}


// ══════════════════════════════════════════════════════════════════
//  MODE 2 — IR LINE FOLLOWING
//  Sensors: LOW = sees black line, HIGH = sees white floor
//  Wiring:  LEFT=A0  MIDDLE=A1  RIGHT=A2
// ══════════════════════════════════════════════════════════════════
#define IR_LEFT    A0
#define IR_MIDDLE  A1
#define IR_RIGHT   A2

// Line turn durations — car steers briefly then re-centres
const unsigned long LINE_TURN_MS = 120;   // ← TUNE: ms of steer per correction
unsigned long lineTurnEnd = 0;
bool lineInCorrection = false;

void initLine() {
  pinMode(IR_LEFT,   INPUT);
  pinMode(IR_MIDDLE, INPUT);
  pinMode(IR_RIGHT,  INPUT);
  steerCentre();
  driveState    = FWD;
  target_speed  = SPD_60;   // Moderate speed for reliable sensing
  current_speed = SPD_60;
  Serial.println("Line: Following...");
}

void tickLine() {
  int sl = digitalRead(IR_LEFT);
  int sm = digitalRead(IR_MIDDLE);
  int sr = digitalRead(IR_RIGHT);

  /*
   * Sensor logic:
   *   sm=LOW  (middle on line)  → steer straight
   *   sl=LOW, sr=HIGH           → line drifted right → steer right
   *   sr=LOW, sl=HIGH           → line drifted left  → steer left
   *   all HIGH (lost line)      → stop and wait
   *   all LOW  (junction/end)   → stop and wait
   */
  if (sm == LOW) {
    // On line — straighten servo
    target_angle = S_CENTRE;
    target_speed = SPD_60;
  } else if (sl == LOW && sr == HIGH) {
    // Line to the right — steer right to correct
    target_angle = S_CENTRE + 25;
    target_speed = SPD_40;
  } else if (sr == LOW && sl == HIGH) {
    // Line to the left — steer left to correct
    target_angle = S_CENTRE - 25;
    target_speed = SPD_40;
  } else {
    // Lost line or junction — slow stop
    target_angle = S_CENTRE;
    target_speed = 0;
  }

  rampServo();
  rampSpeed();
  applyDifferential(current_speed);
}


// ══════════════════════════════════════════════════════════════════
//  MODE 3 — SENTRY2 FACE FOLLOWING
//
//  How it works:
//    • Sentry2 returns the face bounding box every tick:
//        kXValue      — horizontal centre, 0 (left) to 100 (right), 50 = centred
//        kYValue      — vertical centre  (unused for drive, logged only)
//        kWidthValue  — box width  as % of frame
//        kHeightValue — box height as % of frame  ← used as distance proxy
//
//    • STEERING  — proportional controller on X error
//        error = faceX − 50
//        If |error| > FACE_DEAD_ZONE → steerOffset = error × FACE_KP
//        Servo target = S_CENTRE + steerOffset  (clamped to S_MAX_L … S_MAX_R)
//
//    • SPEED  — 3-zone distance control using face height %
//        faceH > FACE_CLOSE_H  →  STOP      (person is too close)
//        faceH < FACE_FAR_H    →  SPD_NORMAL (person is far, chase)
//        otherwise             →  SPD_60 straight / SPD_40 while turning
//
//    • NO FACE DETECTED
//        Car halts and holds its last servo angle so it keeps "looking"
//        in the direction the person was last seen.
//
//  TUNING
//    FACE_KP        Increase for snappier steering; decrease if oscillating
//    FACE_DEAD_ZONE Increase if car hunts left/right when roughly centred
//    FACE_CLOSE_H   Decrease if car stops too early (person still far away)
//    FACE_FAR_H     Increase if car is slow to chase a retreating person
// ══════════════════════════════════════════════════════════════════

#define FACE_KP         2.0f   // Proportional steering gain
#define FACE_DEAD_ZONE  8      // ±units from centre before steering activates
#define FACE_CLOSE_H    55     // Height % above this = too close → stop
#define FACE_FAR_H      15     // Height % below this = too far  → speed up

void initFace() {
  sengo2.VisionBegin(Sengo2::kVisionFace);
  steerCentre();
  target_speed  = 0;
  current_speed = 0;
  driveState    = FWD;
  Serial.println("Face: Scanning for person...");
}

void tickFace() {
  int numFaces = sengo2.GetValue(Sengo2::kVisionFace, kStatus);

  // ── No face detected ────────────────────────────────────────────
  // Stop driving but hold last servo angle — keeps car "looking" toward
  // where the person was last seen so it can re-acquire quickly.
  if (numFaces == 0) {
    target_speed = 0;
    driveState   = STOPPED;
    rampSpeed();
    applyDifferential(current_speed);
    Serial.println("Face: none");
    return;
  }

  // ── Read bounding box of the first (closest/largest) face ───────
  int faceX = sengo2.GetValue(Sengo2::kVisionFace, kXValue,     1); // 0–100
  int faceY = sengo2.GetValue(Sengo2::kVisionFace, kYValue,     1); // 0–100 (logged only)
  int faceW = sengo2.GetValue(Sengo2::kVisionFace, kWidthValue, 1); // 0–100
  int faceH = sengo2.GetValue(Sengo2::kVisionFace, kHeightValue,1); // 0–100 ← distance proxy

  Serial.print("X:"); Serial.print(faceX);
  Serial.print(" Y:"); Serial.print(faceY);
  Serial.print(" W:"); Serial.print(faceW);
  Serial.print(" H:"); Serial.println(faceH);

  // ── Steering — proportional to horizontal error ─────────────────
  // faceX = 50 → face is centred, error = 0
  // faceX < 50 → face is left  → negative error → steer left  (angle < 90)
  // faceX > 50 → face is right → positive error → steer right (angle > 90)
  int error = faceX - 50;

  if (abs(error) > FACE_DEAD_ZONE) {
    float steerOffset = error * FACE_KP;
    target_angle = constrain((int)(S_CENTRE + steerOffset), S_MAX_L, S_MAX_R);
  } else {
    target_angle = S_CENTRE;   // Within dead zone — go straight
  }

  // ── Speed — 3-zone distance control ─────────────────────────────
  if (faceH > FACE_CLOSE_H) {
    // Person is very close — stop to avoid collision
    target_speed = 0;
    driveState   = STOPPED;
    Serial.println("Face: TOO CLOSE — stop");

  } else if (faceH < FACE_FAR_H) {
    // Person is far away — drive faster to catch up
    target_speed = SPD_NORMAL;
    driveState   = FWD;
    Serial.println("Face: FAR — chasing");

  } else {
    // Good following distancew
    driveState = FWD;
    if (abs(error) < FACE_DEAD_ZONE) {
      target_speed = SPD_60;   // Centred — normal follow cruise
    } else {
      target_speed = SPD_40;   // Turning — slower for stability
    }
  }

  rampServo();
  rampSpeed();
  applyDifferential(current_speed);
}


// ══════════════════════════════════════════════════════════════════
//  SETUP
// ══════════════════════════════════════════════════════════════════
void setup() {
  Serial.begin(9600);

  // PCA9685
  pwm.begin();
  pwm.setPWMFreq(60);
  rearStop();

  // Sentry2 (shared by card + face modes)
  Wire.begin();
//  while (SENTRY_OK != sengo2.begin(&Wire)) {
//    Serial.println("Waiting for Sentry2...");
//    delay(1000);
//  }
  Serial.println("Sentry2 OK");

  // Servo home
  setServoAngle(S_CENTRE);
  delay(400);

  // Start in BLE mode
  switchMode(0);

  Serial.println("─────────────────────────────");
  Serial.println("Send 'M' to cycle modes");
  Serial.println("Send '0'-'3' to jump to mode");
  Serial.println("Send 'S' to stop (any mode)");
  Serial.println("─────────────────────────────");
}


// ══════════════════════════════════════════════════════════════════
//  MAIN LOOP
// ══════════════════════════════════════════════════════════════════
void loop() {

  // ── BLE serial handler ─────────────────────────────────────────
  if (Serial.available() > 0) {

    char c = Serial.read();
    Serial.println(c);

    // ── Switch drive configuration ───────────────────────────────
    if (c == '2') {
      driveConfig = DRIVE_2WD;
      Serial.println("Drive Mode: 2WD");
      return;
    }

    if (c == '3') {
      driveConfig = DRIVE_3WD;
      Serial.println("Drive Mode: 3WD");
      return;
    }

    // ── Global commands — work in ALL modes ──────────────────────
    if (c == 'M') { nextMode(); return; }

    // Jump directly to a mode by number
    if (c >= '0' && c < ('0' + MODE_COUNT)) { 
      switchMode(c - '0'); 
      return; 
    }

    // Emergency stop
    if (c == 'S') {
      driveState    = STOPPED;
      target_speed  = 0;
      current_speed = 0;
      rearStop();
      steerCentre();
      Serial.println("STOP");
      return;
    }

    // ── BLE mode commands ───────────────────────────────────────
    if (currentMode == 0) {
      switch (c) {
        case 'F': bleCmdForward();    break;
        case 'B': bleCmdBackward();   break;
        case 'L': steerNudgeLeft();   break;
        case 'R': steerNudgeRight();  break;
        case 'l': bleCmdDriveLeft();  break;
        case 'r': bleCmdDriveRight(); break;
        case 'C': bleCmdCentre();     break;
        case 'U': bleCmdUTurn();      break;
        case 'a': bleCmdSpeedUp();    break;
        case 'd': bleCmdSpeedDown();  break;
        default: break;
      }
    }
  }

  // ── Run current mode ───────────────────────────────────────────
  MODES[currentMode].tick();

  delay(40);
}
