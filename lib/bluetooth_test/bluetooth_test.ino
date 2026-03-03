void setup() {
  Serial.begin(9600);   
  delay(1000);
  Serial.println("Bluetooth Ready");
}

void loop() {

  Serial.println("Hello from Arduino");

  if (Serial.available()) {
    char c = Serial.read();
    Serial.print("Received: ");
    Serial.println(c);
  }

  delay(2000);
}
// test this on arduino IDE, if you are using HM-10, its a BLE, use a third party app to detect it and receive the messege
//Try Serial BluetooTh Terminal
