/*
 * Quick Bluetooth test: 2 rear wheels FORWARD only on 'F'
 * PCA9685 address 0x40, HM-10 on pins 10(RX)/11(TX)
 * For 2-wheel rear drive — no steering in this test
 */

#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>
#include <SoftwareSerial.h>

SoftwareSerial ble(10, 11);  // RX=10 to HM-10 TX, TX=11 to HM-10 RX

Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x40);

#define LEFT_DIR_CH   2
#define LEFT_PWM_CH   3
#define RIGHT_DIR_CH  6
#define RIGHT_PWM_CH  7

#define DIR_FORWARD   4095
#define DIR_REVERSE      0

#define TEST_SPEED    1800   // Adjust higher/lower if too fast/slow (800–2555 range)

void setup() {
  Serial.begin(9600);         // Open Serial Monitor to watch messages
  ble.begin(9600);            // HM-10 baud — change to 115200 if no response

  pwm.begin();
  pwm.setPWMFreq(60);

  stopMotors();               // Ensure stopped at start

  Serial.println("2-wheel rear drive Bluetooth test ready!");
  Serial.println("Send 'F' from Bluetooth app → both rear wheels forward");
  Serial.println("Send 'S' or anything else → stop");
}

void loop() {
  if (ble.available() > 0) {
    char cmd = ble.read();

    Serial.print("Received: '");
    Serial.print(cmd);
    Serial.println("'");

    if (cmd == 'F') {
      goForward();
      Serial.println("→ Both rear wheels moving FORWARD");
    } else {
      stopMotors();
      Serial.println("→ STOPPED");
    }
  }
}

void goForward() {
  // Both wheels same direction + same speed = straight forward
  pwm.setPWM(LEFT_DIR_CH,  0, DIR_FORWARD);
  pwm.setPWM(RIGHT_DIR_CH, 0, DIR_FORWARD);
  pwm.setPWM(LEFT_PWM_CH,  0, TEST_SPEED);
  pwm.setPWM(RIGHT_PWM_CH, 0, TEST_SPEED);
}

void stopMotors() {
  pwm.setPWM(LEFT_PWM_CH,  0, 0);
  pwm.setPWM(RIGHT_PWM_CH, 0, 0);
}
