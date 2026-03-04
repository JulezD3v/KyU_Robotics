/*
 * 2WD Car — PCA9685 Rear Motors + 360° Steering Servo + HM-10 BLE
 *
 * Hardware:
 *   PCA9685 (I2C 0x47):
 *     CH 2 = Left  motor direction
 *     CH 3 = Left  motor PWM speed
 *     CH 6 = Right motor direction
 *     CH 7 = Right motor PWM speed
 *
 *   Steering servo (360° continuous) on Arduino pin 9:
 *     1500 µs = straight  |  1000 µs = left  |  2000 µs = right
 *
 *   HM-10 BLE: TX→RX(0), RX→TX(1) — 9600 baud
 *
 * Flutter BLE Commands:
 *   'F' = forward          'B' = backward        'S' = stop
 *   'L' = pivot left       'R' = pivot right      (short press — spin in place)
 *   'l' = curve left       'r' = curve right      (long press  — forward + steer)
 *   'U' = U-turn
 *   'a' = speed up         'd' = speed down
 */

#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>
#include <Servo.h>

// ── PCA9685 ───────────────────────────────────────────────────────
Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x47);

#define LEFT_DIR_CH   2
#define LEFT_PWM_CH   3
#define RIGHT_DIR_CH  6
#define RIGHT_PWM_CH  7

#define DIR_FORWARD  4095
#define DIR_REVERSE  0

// ── Speed ─────────────────────────────────────────────────────────
const int SPEED_STEP   = 50;
const int SPEED_MIN    = 800;
const int SPEED_MAX    = 2555;
int normalSpeed        = 1800;
int current_speed      = 0;
int target_speed       = 0;   // 0 = stopped at start

// ── Steering servo ────────────────────────────────────────────────
Servo steerServo;
#define STEER_PIN     9
#define STEER_NEUTRAL 1500
#define STEER_LEFT    1000
#define STEER_RIGHT   2000

// ── Current state ─────────────────────────────────────────────────
enum DriveState { STOPPED, FWD, REV, PIVOT_L, PIVOT_R };
DriveState driveState = STOPPED;

// ── Steering helpers ──────────────────────────────────────────────
void steerStraight() { steerServo.writeMicroseconds(STEER_NEUTRAL); }
void steerLeft()     { steerServo.writeMicroseconds(STEER_LEFT);    }
void steerRight()    { steerServo.writeMicroseconds(STEER_RIGHT);   }

// ── Motor raw writes ──────────────────────────────────────────────
void setMotors(int leftDir, int rightDir, int speed) {
  pwm.setPWM(LEFT_DIR_CH,  0, leftDir);
  pwm.setPWM(LEFT_PWM_CH,  0, speed);
  pwm.setPWM(RIGHT_DIR_CH, 0, rightDir);
  pwm.setPWM(RIGHT_PWM_CH, 0, speed);
}

void rearStop() {
  pwm.setPWM(LEFT_PWM_CH,  0, 0);
  pwm.setPWM(RIGHT_PWM_CH, 0, 0);
}

// ── Movement commands ─────────────────────────────────────────────
void cmdForward() {
  steerStraight();
  driveState   = FWD;
  target_speed = normalSpeed;
}

void cmdBackward() {
  steerStraight();
  driveState   = REV;
  target_speed = normalSpeed;
}

void cmdStop() {
  steerStraight();
  driveState   = STOPPED;
  target_speed = 0;
}

// Short press — spin in place
void cmdPivotLeft() {
  steerLeft();
  driveState   = PIVOT_L;
  target_speed = normalSpeed;
}

void cmdPivotRight() {
  steerRight();
  driveState   = PIVOT_R;
  target_speed = normalSpeed;
}

// Long press — forward + steer
void cmdCurveLeft() {
  steerLeft();
  driveState   = FWD;
  target_speed = normalSpeed;
}

void cmdCurveRight() {
  steerRight();
  driveState   = FWD;
  target_speed = normalSpeed;
}

// U-turn: pivot left for ~700 ms then stop
void cmdUTurn() {
  steerLeft();
  driveState     = PIVOT_L;
  current_speed  = normalSpeed;   // skip ramp for instant response
  setMotors(DIR_REVERSE, DIR_FORWARD, normalSpeed);
  delay(700);
  cmdStop();
}

// ── Speed control ─────────────────────────────────────────────────
void cmdSpeedUp() {
  normalSpeed = min(normalSpeed + 200, SPEED_MAX);
  if (driveState != STOPPED) target_speed = normalSpeed;
  Serial.print("Speed="); Serial.println(normalSpeed);
}

void cmdSpeedDown() {
  normalSpeed = max(normalSpeed - 200, SPEED_MIN);
  if (driveState != STOPPED) target_speed = normalSpeed;
  Serial.print("Speed="); Serial.println(normalSpeed);
}

// ── Apply current drive state with a given speed ──────────────────
void applyDrive(int spd) {
  switch (driveState) {
    case FWD:     setMotors(DIR_FORWARD, DIR_FORWARD, spd); break;
    case REV:     setMotors(DIR_REVERSE, DIR_REVERSE, spd); break;
    case PIVOT_L: setMotors(DIR_REVERSE, DIR_FORWARD, spd); break;
    case PIVOT_R: setMotors(DIR_FORWARD, DIR_REVERSE, spd); break;
    case STOPPED: rearStop();                               break;
  }
}

// ── Setup ─────────────────────────────────────────────────────────
void setup() {
  Serial.begin(9600);

  pwm.begin();
  pwm.setPWMFreq(60);
  rearStop();

  steerServo.attach(STEER_PIN);
  steerStraight();
  delay(300);

  Serial.println("2WD BLE Ready");
}

// ── Loop ──────────────────────────────────────────────────────────
void loop() {

  // 1. Read BLE command
  if (Serial.available() > 0) {
    char c = Serial.read();
    Serial.println(c);
    switch (c) {
      case 'F': cmdForward();    break;
      case 'B': cmdBackward();   break;
      case 'S': cmdStop();       break;
      case 'L': cmdPivotLeft();  break;
      case 'R': cmdPivotRight(); break;
      case 'l': cmdCurveLeft();  break;
      case 'r': cmdCurveRight(); break;
      case 'U': cmdUTurn();      break;
      case 'a': cmdSpeedUp();    break;
      case 'd': cmdSpeedDown();  break;
      default:  break;
    }
  }

  // 2. Smooth speed ramp (runs every loop tick ~40 ms)
  if (current_speed != target_speed) {
    int delta = (target_speed > current_speed) ? SPEED_STEP : -SPEED_STEP;
    current_speed += delta;
    if (abs(target_speed - current_speed) < SPEED_STEP) {
      current_speed = target_speed;
    }
  }

  // 3. Apply to motors
  applyDrive(current_speed);

  delay(40);
}
