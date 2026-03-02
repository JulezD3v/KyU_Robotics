void setup() {
  Serial.begin(9600);   // Must match Bluetooth baud rate
  delay(1000);
  Serial.println("Bluetooth Ready");
}

void loop() {

  // Send test message every 2 seconds
  Serial.println("Hello from Arduino");

  // If something is received from phone
  if (Serial.available()) {
    char c = Serial.read();
    Serial.print("Received: ");
    Serial.println(c);
  }

  delay(2000);
}
