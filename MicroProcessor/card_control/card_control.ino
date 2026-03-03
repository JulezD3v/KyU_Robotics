/* NB
   Sengo2 Card Control for 3-Wheel Rear Drive Robot
   - Uses rear wheels only (channels 2,3,6,7 on PCA9685)
   - Sengo2 detects traffic cards:
     - Red/Stop sign (label 5): Stop
     - Green/Forward (label 1): Forward at normal speed
     - Speed 40 (label 8): Forward at extra slow speed
     - Speed 60 (label 9): Forward at slow speed
     - Speed 80 (label 10): Forward at full speed
     - Left (label 2): Turn left (pivot)
     - Right (label 3): Turn right (pivot)
   - Persists the last detected action until a new card is seen (does not stop on no card)
   - Assumes standard Keyestudio traffic card labels (confirmed: 1=forward/green, 5=stop/red, 8=40, 9=60, 10=80, 2=left, 3=right)
   - No arm, no other sensors/modes
   - Turns are implemented as pivot turns (one side reverse, other forward) at normal speed
*/

#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>
#include <Sentry.h>

// PWM driver for motors (address 0x47)
Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x47);

// Sengo2 camera (address 0x60)
Sengo2 sengo2(0x60);

// Motor channels
#define LEFT_DIR_CH  2
#define LEFT_PWM_CH  3
#define RIGHT_DIR_CH 6
#define RIGHT_PWM_CH 7

// Direction values (assuming PWM 0-4095 for dir: 4095 = forward, 0 = reverse)
#define DIR_FORWARD 4095
#define DIR_REVERSE 0

// Speeds (adjust as needed; PWM 0-4095, but capped for your setup)
const int speed40 = 1000;     // Speed 40 card (extra slow)
const int slowSpeed = 1200;   // Speed 60 card
const int normalSpeed = 1800; // Green/Forward card or turns
const int fullSpeed = 2500;   // Speed 80 card

// Card labels (from Keyestudio traffic set)
const int labelForward = 1;   // Green / Forward
const int labelLeft = 2;      // Turn left
const int labelRight = 3;     // Turn right
const int labelStop = 5;      // Red light / Stop sign
const int labelSpeed40 = 8;   // 40% speed
const int labelSpeed60 = 9;   // 60% speed
const int labelSpeed80 = 10;  // 80% speed

// Persistent state
int lastLabel = labelStop;    // Start with stop

void setup() {
  Serial.begin(9600);
  Serial.println("Initializing...");

  Wire.begin();

  // Init PWM for motors
  pwm.begin();
  pwm.setPWMFreq(60);

  // Init Sengo2
  while (SENTRY_OK != sengo2.begin(&Wire)) {
    Serial.println("Sengo2 init failed - check wiring");
    delay(1000);
  }
  Serial.println("Sengo2 initialized");

  // Start card vision
  sengo2.VisionBegin(Sengo2::kVisionCard);

  // Initial stop
  rearStop();
}

void loop() {
  int numCards = sengo2.GetValue(Sengo2::kVisionCard, kStatus);

  int detectedLabel = 0;  // Default no new action

  if (numCards > 0) {
    // Get the first detected card's label (priority to first)
    detectedLabel = sengo2.GetValue(Sengo2::kVisionCard, kLabel, 1);
    Serial.print("Detected card label: ");
    Serial.println(detectedLabel);
  } else {
    Serial.println("No card detected - continuing with last action");
  }

  // Update lastLabel only if a valid new card is detected
  if (detectedLabel > 0) {
    lastLabel = detectedLabel;
  }

  // Control based on lastLabel
  switch (lastLabel) {
    case labelStop:
      rearStop();
      Serial.println("Red/Stop → Stopped");
      break;
    case labelForward:
      rearForward(normalSpeed);
      Serial.println("Green/Forward → Normal speed");
      break;
    case labelSpeed40:
      rearForward(speed40);
      Serial.println("Speed 40 → Extra slow speed");
      break;
    case labelSpeed60:
      rearForward(slowSpeed);
      Serial.println("Speed 60 → Slow speed");
      break;
    case labelSpeed80:
      rearForward(fullSpeed);
      Serial.println("Speed 80 → Full speed");
      break;
    case labelLeft:
      rearLeft();
      Serial.println("Left → Turning left");
      break;
    case labelRight:
      rearRight();
      Serial.println("Right → Turning right");
      break;
    default:
      rearStop();  // Unknown → stop (safety)
      Serial.println("Unknown card → Stopped");
      break;
  }

  delay(200);  // Update every 0.2s
}

// Rear wheels forward at given speed
void rearForward(int spd) {
  // Clamp speed
  spd = constrain(spd, 0, 4095);

  pwm.setPWM(LEFT_DIR_CH, 0, DIR_FORWARD);
  pwm.setPWM(LEFT_PWM_CH, 0, spd);
  pwm.setPWM(RIGHT_DIR_CH, 0, DIR_FORWARD);
  pwm.setPWM(RIGHT_PWM_CH, 0, spd);
}

// Pivot turn left (left reverse, right forward)
void rearLeft() {
  pwm.setPWM(LEFT_DIR_CH, 0, DIR_REVERSE);
  pwm.setPWM(LEFT_PWM_CH, 0, normalSpeed);
  pwm.setPWM(RIGHT_DIR_CH, 0, DIR_FORWARD);
  pwm.setPWM(RIGHT_PWM_CH, 0, normalSpeed);
}

// Pivot turn right (left forward, right reverse)
void rearRight() {
  pwm.setPWM(LEFT_DIR_CH, 0, DIR_FORWARD);
  pwm.setPWM(LEFT_PWM_CH, 0, normalSpeed);
  pwm.setPWM(RIGHT_DIR_CH, 0, DIR_REVERSE);
  pwm.setPWM(RIGHT_PWM_CH, 0, normalSpeed);
}

// Stop rear wheels
void rearStop() {
  pwm.setPWM(LEFT_PWM_CH, 0, 0);
  pwm.setPWM(RIGHT_PWM_CH, 0, 0);
  // Dir can stay as is, since PWM=0 stops
}

// works, confirm camera wiring R/D goes to A4
