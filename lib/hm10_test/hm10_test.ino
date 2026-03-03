#include <SoftwareSerial.h>

SoftwareSerial ble(10, 11);  // RX=10 (from HM-10 TX), TX=11 (to HM-10 RX)

void setup() {
  Serial.begin(9600);
  //ble.begin(9600);           // First try this
  ble.begin(115200);      // Uncomment & re-upload if nothing below works

  Serial.println("=== HM-10 DEBUG TEST ===");
  Serial.println("Open Bluetooth serial app → connect to HM-10");
  Serial.println("Send ANY letter (like F, S, x, whatever)");
  Serial.println("Watch this Serial Monitor for EVERY received byte");
}

void loop() {
  if (ble.available() > 0) {
    char incoming = ble.read();
    Serial.print("GOT something! Char = '");
    Serial.print(incoming);
    Serial.print("'  (ASCII code: ");
    Serial.print((int)incoming);
    Serial.println(")");
  }

  // Optional: echo back what you type in Serial Monitor to phone
  if (Serial.available() > 0) {
    ble.write(Serial.read());
  }
}
