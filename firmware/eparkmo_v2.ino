// ============================================================
// E-PARK MO — SMART PARKING SYSTEM (UPDATED v3)
// ============================================================
// CHANGES FROM v2:
// 1. FIXED: Firestore HTTP calls moved to separate FreeRTOS task
//           (Core 0) — hindi na nahaharang ang gate at sensors
// 2. FIXED: Gate handlers now run uninterrupted on Core 1
// 3. CHANGED: Firestore refresh rate → 3 seconds
// 4. ADDED: Mutex para sa thread-safe na slot status access
// ============================================================
// PIN SUMMARY:
// Entrance IR (dedicated) → GPIO 34
// Exit IR (dedicated)     → GPIO 35
// Slot 1-6 IR             → GPIO 23,22,21,19,18,5
// Entrance Servo          → GPIO 17
// Exit Servo              → GPIO 14
// Buzzer                  → GPIO 4 (low level trigger)
// LCD SDA                 → GPIO 25
// LCD SCL                 → GPIO 26
// ============================================================

// ============================================================
// LIBRARIES
// ============================================================
#include <WiFi.h>
#include <HTTPClient.h>
#include <ESP32Servo.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// ============================================================
// WIFI CREDENTIALS
// ============================================================
const char* ssid     = "JC 2.4G";
const char* password = "03212005";

// ============================================================
// FIREBASE CREDENTIALS
// ============================================================
const char* PROJECT_ID = "e-park-mo-fe42a";
const char* API_KEY    = "AIzaSyD7DKAWGVDlESVWfIqC0NIQjJJhRyL7ZaI";

// ============================================================
// OBJECTS
// ============================================================
LiquidCrystal_I2C lcd(0x27, 16, 2);
Servo servoEntrance, servoExit;

// ============================================================
// PIN DEFINITIONS
// ============================================================
const int irPins[6]        = {23, 22, 21, 19, 18, 5};
const int irEntrancePin    = 34;
const int irExitPin        = 35;
const int servoEntrancePin = 17;
const int servoExitPin     = 14;
const int buzzerPin        = 4;

// ============================================================
// SLOT STATUS
// 0 = available, 1 = occupied, 2 = reserved
// ============================================================
int slotStatus[6]       = {0, 0, 0, 0, 0, 0};
int lastPushedStatus[6] = {-1, -1, -1, -1, -1, -1};

const char* slotIds[6] = {"slot-1","slot-2","slot-3","slot-4","slot-5","slot-6"};

// ============================================================
// MUTEX — thread-safe access sa slotStatus
// ============================================================
SemaphoreHandle_t slotMutex;

// ============================================================
// SERVO POSITIONS
// ============================================================
const int ENTRANCE_CLOSED = 0;
const int ENTRANCE_OPEN   = 90;
const int EXIT_CLOSED     = 170;
const int EXIT_OPEN       = 80;

// ============================================================
// GATE SENSITIVITY SETTINGS
// ============================================================
const int           GATE_CONFIRM_NEEDED = 5;
const unsigned long GATE_MIN_HOLD       = 300;
const unsigned long GATE_CLOSE_DELAY    = 5000;

// ============================================================
// SLOT SENSITIVITY SETTINGS
// ============================================================
const int           SLOT_CONFIRM_NEEDED = 5;
const unsigned long SLOT_DEBOUNCE       = 500;

// ============================================================
// GATE STATE — ENTRANCE
// ============================================================
bool          entranceOpen       = false;
int           entranceConfirm    = 0;
unsigned long entranceOpenedAt   = 0;
unsigned long entranceDetectedAt = 0;
unsigned long entranceClearAt    = 0;

// ============================================================
// GATE STATE — EXIT
// ============================================================
bool          exitOpen       = false;
int           exitConfirm    = 0;
unsigned long exitOpenedAt   = 0;
unsigned long exitDetectedAt = 0;
unsigned long exitClearAt    = 0;

// ============================================================
// SLOT DEBOUNCE TRACKING
// ============================================================
int           slotConfirm[6]    = {0, 0, 0, 0, 0, 0};
unsigned long slotDetectedAt[6] = {0, 0, 0, 0, 0, 0};
int           slotLastState[6]  = {0, 0, 0, 0, 0, 0};

// ============================================================
// LCD STATE
// ============================================================
unsigned long lastLCDUpdate         = 0;
bool          showingGateStatus     = false;
unsigned long gateDisplayAt         = 0;
const unsigned long GATE_DISPLAY_MS = 3000;

// ============================================================
// FIRESTORE SETTINGS
// ✅ 3 seconds refresh rate
// ============================================================
const unsigned long SLOT_PUSH_INTERVAL     = 3000;
const unsigned long FIRESTORE_POLL_INTERVAL = 3000;
const int           HTTP_TIMEOUT_MS         = 3000;

String firestoreBase;

// ============================================================
// RESERVATION TRIGGER FLAG
// ============================================================
volatile bool reservationTrigger = false;

// ============================================================
// HELPER — BUZZER (low level trigger)
// ============================================================
void buzzerOn()  { digitalWrite(buzzerPin, LOW);  }
void buzzerOff() { digitalWrite(buzzerPin, HIGH); }

void tripleBeep() {
  for (int i = 0; i < 3; i++) {
    buzzerOn();  delay(200);
    buzzerOff(); if (i < 2) delay(100);
  }
}

// ============================================================
// HELPER — CHECK IF PARKING IS FULL
// ============================================================
bool isParkingFull() {
  for (int i = 0; i < 6; i++) {
    if (slotStatus[i] == 0) return false;
  }
  return true;
}

// ============================================================
// HELPER — CHECK IF HAS RESERVED SLOT
// ============================================================
bool hasReservedSlot() {
  for (int i = 0; i < 6; i++) {
    if (slotStatus[i] == 2) return true;
  }
  return false;
}

// ============================================================
// HELPER — SHOW GATE STATUS ON LCD
// ============================================================
void showGateStatus(bool isEntrance, bool isOpen) {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(isEntrance ? "    ENTRANCE    " : "      EXIT      ");
  lcd.setCursor(0, 1);
  lcd.print(isOpen     ? "   GATE OPEN    " : "   GATE CLOSED  ");
  showingGateStatus = true;
  gateDisplayAt     = millis();
}

// ============================================================
// HELPER — UPDATE LCD MAIN DISPLAY
// ============================================================
void updateLCD() {
  if (showingGateStatus && millis() - gateDisplayAt < GATE_DISPLAY_MS) return;
  showingGateStatus = false;

  int available = 0, reserved = 0;
  for (int i = 0; i < 6; i++) {
    if (slotStatus[i] == 0) available++;
    if (slotStatus[i] == 2) reserved++;
  }

  lcd.setCursor(0, 0);
  if (isParkingFull()) {
    lcd.print("   E-Park Mo    ");
    lcd.setCursor(0, 1);
    lcd.print(" PARKING FULL!  ");
  } else {
    lcd.print("   E-Park Mo    ");
    lcd.setCursor(0, 1);
    String line2 = "Avail:" + String(available) + " Resv:" + String(reserved) + "  ";
    lcd.print(line2);
  }
}

// ============================================================
// SLOT UPDATE — WITH DEBOUNCE
// ============================================================
void updateSlots() {
  if (xSemaphoreTake(slotMutex, 10) != pdTRUE) return;

  for (int i = 0; i < 6; i++) {
    int reading = (digitalRead(irPins[i]) == LOW) ? 1 : 0;

    // Reserved slot — transition to occupied if car detected
    if (slotStatus[i] == 2) {
      if (reading == 1) {
        slotStatus[i]    = 1;
        slotLastState[i] = 1;
        Serial.println(String(slotIds[i]) + " reserved → occupied");
      }
      continue;
    }

    // Normal debounce
    if (reading != slotLastState[i]) {
      if (slotDetectedAt[i] == 0) slotDetectedAt[i] = millis();
      slotConfirm[i]++;
      if (slotConfirm[i] >= SLOT_CONFIRM_NEEDED &&
          millis() - slotDetectedAt[i] >= SLOT_DEBOUNCE) {
        slotStatus[i]     = reading;
        slotLastState[i]  = reading;
        slotConfirm[i]    = 0;
        slotDetectedAt[i] = 0;
      }
    } else {
      slotConfirm[i]    = 0;
      slotDetectedAt[i] = 0;
    }
  }

  xSemaphoreGive(slotMutex);
}

// ============================================================
// FIRESTORE — PUSH SLOT STATUS
// ============================================================
void pushSlotsToFirestore() {
  if (WiFi.status() != WL_CONNECTED) return;

  // Take snapshot of slot status (thread-safe)
  int snapshot[6];
  if (xSemaphoreTake(slotMutex, 100) == pdTRUE) {
    for (int i = 0; i < 6; i++) snapshot[i] = slotStatus[i];
    xSemaphoreGive(slotMutex);
  } else return;

  for (int i = 0; i < 6; i++) {
    if (snapshot[i] == lastPushedStatus[i]) continue;

    String statusStr;
    if      (snapshot[i] == 1) statusStr = "occupied";
    else if (snapshot[i] == 2) statusStr = "reserved";
    else                       statusStr = "available";

    String url = firestoreBase + "/slots/" + slotIds[i] +
                 "?updateMask.fieldPaths=status" +
                 "&updateMask.fieldPaths=isSensorActive" +
                 "&key=" + String(API_KEY);

    String body = "{\"fields\":{"
                  "\"status\":{\"stringValue\"😕"" + statusStr + "\"},"
                  "\"isSensorActive\":{\"booleanValue\":true}"
                  "}}";

    HTTPClient http;
    http.begin(url);
    http.setTimeout(HTTP_TIMEOUT_MS);
    http.addHeader("Content-Type", "application/json");
    int code = http.PATCH(body);

    if (code == 200) {
      lastPushedStatus[i] = snapshot[i];
      Serial.println(String(slotIds[i]) + " → " + statusStr + " ✓");
    } else {
      Serial.println(String(slotIds[i]) + " push failed. HTTP: " + String(code));
    }
    http.end();
  }
}

// ============================================================
// FIRESTORE — POLL RESERVATIONS + BARRIER
// ============================================================
void pollFirestore() {
  if (WiFi.status() != WL_CONNECTED) return;

  // ── 1. Batch-read ALL slots ─────────────────────────────
  String slotsUrl = firestoreBase + "/slots?key=" + String(API_KEY);
  HTTPClient http;
  http.begin(slotsUrl);
  http.setTimeout(HTTP_TIMEOUT_MS);
  int code = http.GET();

  if (code == 200) {
    String payload = http.getString();

    int localSnapshot[6];
    if (xSemaphoreTake(slotMutex, 100) == pdTRUE) {
      for (int i = 0; i < 6; i++) localSnapshot[i] = slotStatus[i];
      xSemaphoreGive(slotMutex);
    }

    for (int i = 0; i < 6; i++) {
      String slotMarker = String("/slots/") + slotIds[i];
      int docPos = payload.indexOf(slotMarker);
      if (docPos < 0) continue;

      String nextMarker = (i < 5) ? String("/slots/") + slotIds[i + 1] : "NOT_FOUND";
      int nextPos = payload.indexOf(nextMarker, docPos + 1);
      String slotSection = (nextPos > 0)
        ? payload.substring(docPos, nextPos)
        : payload.substring(docPos);

      bool isReserved  = slotSection.indexOf("\"reserved\"")  > 0;
      bool isAvailable = slotSection.indexOf("\"available\"") > 0;
      bool isOccupied  = slotSection.indexOf("\"occupied\"")  > 0;

      if (xSemaphoreTake(slotMutex, 100) == pdTRUE) {
        if (isReserved && slotStatus[i] != 2) {
          slotStatus[i] = 2; slotLastState[i] = 2;
          Serial.println(String(slotIds[i]) + " synced → reserved");
        } else if (isAvailable && slotStatus[i] == 2) {
          slotStatus[i] = 0; slotLastState[i] = 0;
          Serial.println(String(slotIds[i]) + " synced → available");
        } else if (isOccupied && slotStatus[i] == 2) {
          slotStatus[i] = 1; slotLastState[i] = 1;
          Serial.println(String(slotIds[i]) + " synced → occupied");
        }
        xSemaphoreGive(slotMutex);
      }
    }
  } else {
    Serial.println("Slots batch read failed. HTTP: " + String(code));
  }
  http.end();

  // ── 2. Poll barrier/gate ────────────────────────────────
  String barrierUrl = firestoreBase + "/barrier/gate?key=" + String(API_KEY);
  HTTPClient http2;
  http2.begin(barrierUrl);
  http2.setTimeout(HTTP_TIMEOUT_MS);
  code = http2.GET();

  if (code == 200) {
    String payload = http2.getString();
    bool isOpen = payload.indexOf("\"booleanValue\":true") > 0;

    if (isOpen) {
      reservationTrigger = true;
      Serial.println(">> App triggered barrier open.");

      // Reset isOpen in Firestore
      String resetUrl = firestoreBase + "/barrier/gate" +
                        "?updateMask.fieldPaths=isOpen" +
                        "&key=" + String(API_KEY);
      String resetBody = "{\"fields\":{\"isOpen\":{\"booleanValue\":false}}}";

      HTTPClient resetHttp;
      resetHttp.begin(resetUrl);
      resetHttp.setTimeout(HTTP_TIMEOUT_MS);
      resetHttp.addHeader("Content-Type", "application/json");
      resetHttp.PATCH(resetBody);
      resetHttp.end();
    }
  }
  http2.end();
}

// ============================================================
// FIRESTORE TASK — runs on Core 0
// ✅ Hindi na nahaharang ang gate at sensors
// ============================================================
void firestoreTask(void* parameter) {
  unsigned long lastPush = 0;
  unsigned long lastPoll = 0;

  for (;;) {
    unsigned long now = millis();

    // Push every 3 seconds
    if (now - lastPush >= SLOT_PUSH_INTERVAL) {
      lastPush = now;
      pushSlotsToFirestore();
    }

    // Poll every 3 seconds (offset by 1.5s from push)
    if (now - lastPoll >= FIRESTORE_POLL_INTERVAL) {
      lastPoll = now;
      pollFirestore();
    }

    vTaskDelay(100 / portTICK_PERIOD_MS); // yield every 100ms
  }
}

// ============================================================
// GATE HANDLER
// ============================================================
void handleGate(int irPin, Servo &servo,
                bool &isOpen, int &confirmCount,
                unsigned long &openedAt, unsigned long &detectedAt,
                unsigned long &clearAt,
                int closedPos, int openPos,
                bool isEntrance) {

  if (isOpen) {
    bool stillDetecting = (digitalRead(irPin) == LOW);
    if (stillDetecting) {
      clearAt = 0;
    } else {
      if (clearAt == 0) clearAt = millis();
      if (millis() - clearAt >= GATE_CLOSE_DELAY) {
        Serial.println(isEntrance ? ">> Entrance closing." : ">> Exit closing.");
        servo.write(closedPos);
        if (isEntrance) {
          showGateStatus(true, false);
        } else {
          tripleBeep();
        }
        isOpen       = false;
        confirmCount = 0;
        detectedAt   = 0;
        clearAt      = 0;
      }
    }
    return;
  }

  if (isEntrance) {
    if (reservationTrigger) {
      Serial.println(">> App trigger — Opening entrance!");
      showGateStatus(true, true);
      servo.write(openPos);
      openedAt           = millis();
      isOpen             = true;
      confirmCount       = 0;
      detectedAt         = 0;
      clearAt            = 0;
      reservationTrigger = false;
      return;
    }

    if (isParkingFull()) {
      Serial.println(">> Parking full — Entrance blocked.");
      return;
    }
  }

  int irState = digitalRead(irPin);
  if (irState == LOW) {
    if (detectedAt == 0) detectedAt = millis();
    confirmCount++;
    if (confirmCount >= GATE_CONFIRM_NEEDED &&
        millis() - detectedAt >= GATE_MIN_HOLD) {
      Serial.println(isEntrance ? ">> Entrance opening!" : ">> Exit opening!");
      if (isEntrance) {
        showGateStatus(true, true);
      } else {
        tripleBeep();
      }
      servo.write(openPos);
      openedAt     = millis();
      isOpen       = true;
      confirmCount = 0;
      detectedAt   = 0;
      clearAt      = 0;
    }
  } else {
    confirmCount = 0;
    detectedAt   = 0;
  }
}

// ============================================================
// SETUP
// ============================================================
void setup() {
  gpio_set_direction(GPIO_NUM_4, GPIO_MODE_OUTPUT);
  gpio_set_level(GPIO_NUM_4, 1);

  Serial.begin(115200);
  delay(1000);

  // ✅ Create mutex para sa thread-safe slot access
  slotMutex = xSemaphoreCreateMutex();

  Wire.begin(25, 26);
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0); lcd.print("Welcome To      ");
  lcd.setCursor(0, 1); lcd.print("  E-Park Mo!    ");
  delay(5000);
  lcd.clear();

  for (int i = 0; i < 6; i++) pinMode(irPins[i], INPUT);
  pinMode(irEntrancePin, INPUT);
  pinMode(irExitPin,     INPUT);
  pinMode(buzzerPin, OUTPUT);
  buzzerOff();

  servoEntrance.attach(servoEntrancePin, 500, 2400);
  servoExit.attach(servoExitPin, 500, 2400);
  servoEntrance.write(ENTRANCE_CLOSED);
  servoExit.write(EXIT_CLOSED);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  lcd.setCursor(0, 0); lcd.print("  E-Park Mo     ");
  lcd.setCursor(0, 1); lcd.print("Connecting WiFi.");

  Serial.print("Connecting to WiFi");
  unsigned long wifiStart = millis();
  while (WiFi.status() != WL_CONNECTED) {
    delay(400);
    Serial.print(".");
    if (millis() - wifiStart > 20000) {
      Serial.println("\nWiFi timeout. Running without WiFi.");
      lcd.setCursor(0, 1); lcd.print("WiFi Failed!    ");
      delay(2000);
      break;
    }
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nConnected! IP: " + WiFi.localIP().toString());
    lcd.setCursor(0, 1); lcd.print("WiFi Connected! ");
    delay(2000);

    firestoreBase = "https://firestore.googleapis.com/v1/projects/" +
                    String(PROJECT_ID) +
                    "/databases/(default)/documents";

    // ✅ Start Firestore task on Core 0
    // Main loop runs on Core 1 — gate + sensors hindi nahaharang
    xTaskCreatePinnedToCore(
      firestoreTask,    // function
      "FirestoreTask",  // name
      16384,            // stack size (16KB — enough for HTTP)
      NULL,             // parameter
      1,                // priority
      NULL,             // handle
      0                 // ✅ Core 0
    );

    Serial.println("Firestore task started on Core 0.");
  }
}

// ============================================================
// LOOP — runs on Core 1
// ✅ Gate handlers + IR sensors + LCD — walang interruption
// ============================================================
void loop() {
  unsigned long now = millis();

  // 1. Read IR sensors with debounce
  updateSlots();

  // 2. Update LCD every 500ms
  if (now - lastLCDUpdate > 500) {
    lastLCDUpdate = now;
    updateLCD();
  }

  // 3. Debug print every 1s
  static unsigned long lastPrint = 0;
  if (now - lastPrint > 1000) {
    lastPrint = now;
    Serial.print("Slots: ");
    for (int i = 0; i < 6; i++) {
      Serial.print(slotStatus[i]);
      Serial.print(i < 5 ? "," : "\n");
    }
    Serial.print("Entrance IR: ");
    Serial.println(digitalRead(irEntrancePin) == LOW ? "DETECTED" : "CLEAR");
    Serial.print("Exit IR:     ");
    Serial.println(digitalRead(irExitPin) == LOW ? "DETECTED" : "CLEAR");
    Serial.print("Parking Full: ");
    Serial.println(isParkingFull() ? "YES" : "NO");
  }

  // 4. Gate handlers — walang interruption mula sa HTTP
  handleGate(irEntrancePin, servoEntrance,
             entranceOpen, entranceConfirm,
             entranceOpenedAt, entranceDetectedAt,
             entranceClearAt,
             ENTRANCE_CLOSED, ENTRANCE_OPEN, true);

  handleGate(irExitPin, servoExit,
             exitOpen, exitConfirm,
             exitOpenedAt, exitDetectedAt,
             exitClearAt,
             EXIT_CLOSED, EXIT_OPEN, false);

  delay(50);
}