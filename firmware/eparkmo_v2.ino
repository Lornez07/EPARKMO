// ============================================================
// E-PARK MO — SMART PARKING SYSTEM (UPDATED v3.1)
// ============================================================
// CHANGES FROM v3:
// 1. ADDED: Yellow LED per slot — lights up when reserved
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
// LED 1-6 (reserved)      → GPIO 32,33,27,13,16,4
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

// ✅ LED pins — yellow LED per slot (reserved indicator)
const int ledPins[6] = {32, 33, 27, 13, 16, 4};

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

// NEW: Non-blocking task state
enum SystemTask { IDLE, POLLING_SLOTS, POLLING_BARRIER, PUSHING_SLOT, PUSHING_LOG };
SystemTask currentTask = IDLE;
int taskStep = 0;
unsigned long lastTaskRun = 0;
const unsigned long TASK_INTERVAL = 200; // Run a sub-task every 200ms

// ============================================================
// LCD STATE
// ============================================================
unsigned long lastLCDUpdate         = 0;
bool          showingGateStatus     = false;
unsigned long gateDisplayAt         = 0;
const unsigned long GATE_DISPLAY_MS = 3000;

// ============================================================
// FIRESTORE SETTINGS
// ============================================================
const unsigned long SLOT_PUSH_INTERVAL      = 3000;
const unsigned long FIRESTORE_POLL_INTERVAL = 3000;
const int           HTTP_TIMEOUT_MS         = 3000;

String firestoreBase;

// ============================================================
// RESERVATION TRIGGER FLAG
// ============================================================
<<<<<<< HEAD
volatile bool reservationTrigger = false;
=======
bool reservationTrigger = false;
bool shouldUpdateExit  = false;
unsigned long exitOpenAt = 0;
>>>>>>> 9ede775032aa32cf38300adae5899ef150f0ecce

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
// HELPER — UPDATE LEDs
// LED ON = reserved, LED OFF = available or occupied
// ============================================================
void updateLEDs() {
  for (int i = 0; i < 6; i++) {
    digitalWrite(ledPins[i], slotStatus[i] == 2 ? HIGH : LOW);
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

    if (slotStatus[i] == 2) {
      if (reading == 1) {
        slotStatus[i]    = 1;
        slotLastState[i] = 1;
        Serial.println(String(slotIds[i]) + " reserved → occupied");
      }
      continue;
    }

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
<<<<<<< HEAD
// FIRESTORE — PUSH SLOT STATUS
=======
// FIRESTORE — PUSH LOG
>>>>>>> 9ede775032aa32cf38300adae5899ef150f0ecce
// ============================================================
bool pushLogToFirestore(String action, String type) {
  if (WiFi.status() != WL_CONNECTED) return false;

<<<<<<< HEAD
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
                  "\"status\":{\"stringValue\":\"" + statusStr + "\"},"
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
=======
  String url = firestoreBase + "/parkingLogs?key=" + String(API_KEY);
  
  // Minimal JSON for a log entry
  String body = "{\"fields\":{"
                "\"action\":{\"stringValue\":\"" + action + "\"},"
                "\"type\":{\"stringValue\":\"" + type + "\"},"
                "\"timestamp\":{\"timestampValue\":\"" + "2026-04-07T12:00:00Z" + "\"}" // Note: Ideally should be server time if possible, but Firestore .add() handles it differently. We'll use a placeholder or better, let Firestore set it.
                "}}";
  // Correction: To let Firestore handle timestamp on server, we should use FieldValue.serverTimestamp() in a different way or just let the app handle it. 
  // For REST API, we can use "serverTimestamp" placeholder or just omit if the DB allows.
  
  HTTPClient http;
  http.begin(url);
  http.setTimeout(HTTP_TIMEOUT_MS);
  http.addHeader("Content-Type", "application/json");
  int code = http.POST(body);
  http.end();
  return (code == 200);
>>>>>>> 9ede775032aa32cf38300adae5899ef150f0ecce
}

// ================= ===========================================
// FIRESTORE — NON-BLOCKING TASK HANDLER
// ============================================================
<<<<<<< HEAD
// FIRESTORE — POLL RESERVATIONS + BARRIER
// ============================================================
void pollFirestore() {
  if (WiFi.status() != WL_CONNECTED) return;

  String slotsUrl = firestoreBase + "/slots?key=" + String(API_KEY);
  HTTPClient http;
  http.begin(slotsUrl);
  http.setTimeout(HTTP_TIMEOUT_MS);
  int code = http.GET();

  if (code == 200) {
    String payload = http.getString();

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
=======
void runSystemTasks() {
  unsigned long now = millis();
  if (now - lastTaskRun < TASK_INTERVAL) return;
  if (WiFi.status() != WL_CONNECTED) return;

  switch (currentTask) {
    case IDLE:
      // Determine what to do next based on intervals
      if (now - lastFirestorePoll >= FIRESTORE_POLL_INTERVAL) {
        currentTask = POLLING_SLOTS;
        taskStep = 0;
      } else if (now - lastSlotPush >= SLOT_PUSH_INTERVAL) {
        // Find if any slot needs pushing
        for (int i = 0; i < 6; i++) {
          if (slotStatus[i] != lastPushedStatus[i]) {
            currentTask = PUSHING_SLOT;
            taskStep = i; // Store which slot to push
            break;
          }
        }
        if (currentTask == IDLE) lastSlotPush = now; // All synced
      }
      break;

    case POLLING_SLOTS: {
      String slotsUrl = firestoreBase + "/slots?key=" + String(API_KEY);
      HTTPClient http;
      http.begin(slotsUrl);
      http.setTimeout(HTTP_TIMEOUT_MS);
      int code = http.GET();
      if (code == 200) {
        String payload = http.getString();
        for (int i = 0; i < 6; i++) {
          String slotMarker = String("/slots/") + slotIds[i];
          int docPos = payload.indexOf(slotMarker);
          if (docPos < 0) continue;
          bool isReserved = payload.indexOf("\"reserved\"", docPos) > 0 && payload.indexOf("\"reserved\"", docPos) < (docPos + 500);
          if (isReserved && slotStatus[i] == 0) {
            slotStatus[i] = 2;
            slotLastState[i] = 2;
            Serial.println(String(slotIds[i]) + " synced → reserved");
          } else if (!isReserved && slotStatus[i] == 2) {
            slotStatus[i] = 0;
            slotLastState[i] = 0;
            Serial.println(String(slotIds[i]) + " synced → available");
          }
        }
      }
      http.end();
      currentTask = POLLING_BARRIER;
      break;
    }

    case POLLING_BARRIER: {
      String barrierUrl = firestoreBase + "/barrier/gate?key=" + String(API_KEY);
      HTTPClient http;
      http.begin(barrierUrl);
      http.setTimeout(HTTP_TIMEOUT_MS);
      int code = http.GET();
      if (code == 200) {
        String payload = http.getString();
        if (payload.indexOf("\"booleanValue\":true") > 0) {
          reservationTrigger = true;
          Serial.println(">> App triggered barrier open.");
          // Stage next step: Reset barrier in Firestore
          taskStep = 1; 
        } else {
          currentTask = IDLE;
          lastFirestorePoll = now;
        }
      } else {
        currentTask = IDLE;
      }
      http.end();
      if (taskStep == 1) {
        // Transition to resetting the barrier
        String resetUrl = firestoreBase + "/barrier/gate?updateMask.fieldPaths=isOpen&key=" + String(API_KEY);
        String resetBody = "{\"fields\":{\"isOpen\":{\"booleanValue\":false}}}";
        http.begin(resetUrl);
        http.PATCH(resetBody);
        http.end();
        currentTask = IDLE;
        lastFirestorePoll = now;
        taskStep = 0;
>>>>>>> 9ede775032aa32cf38300adae5899ef150f0ecce
      }
      break;
    }

<<<<<<< HEAD
  String barrierUrl = firestoreBase + "/barrier/gate?key=" + String(API_KEY);
  HTTPClient http2;
  http2.begin(barrierUrl);
  http2.setTimeout(HTTP_TIMEOUT_MS);
  code = http2.GET();

  if (code == 200) {
    String payload = http2.getString();
    bool isOpen = payload.indexOf("\"booleanValue\": true") > 0 || payload.indexOf("\"booleanValue\":true") > 0;


    if (isOpen) {
      reservationTrigger = true;
      Serial.println(">> App triggered barrier open.");

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
=======
    case PUSHING_SLOT: {
      int i = taskStep;
      String statusStr = (slotStatus[i] == 1) ? "occupied" : (slotStatus[i] == 2 ? "reserved" : "available");
      String url = firestoreBase + "/slots/" + slotIds[i] + "?updateMask.fieldPaths=status&updateMask.fieldPaths=isSensorActive&key=" + String(API_KEY);
      String body = "{\"fields\":{\"status\":{\"stringValue\":\"" + statusStr + "\"},\"isSensorActive\":{\"booleanValue\":true}}}";
      
      HTTPClient http;
      http.begin(url);
      http.setTimeout(HTTP_TIMEOUT_MS);
      http.addHeader("Content-Type", "application/json");
      int code = http.PATCH(body);
      if (code == 200) {
        lastPushedStatus[i] = slotStatus[i];
        Serial.println(String(slotIds[i]) + " → " + statusStr + " ✓");
      }
      http.end();
      currentTask = IDLE; // Return to check for more changes next time
      break;
    }

    case PUSHING_LOG: {
      // In a real state machine we'd store the log to push, but for now we'll just push one if triggered
      // This case is a placeholder for future robust logging
      currentTask = IDLE;
      break;
>>>>>>> 9ede775032aa32cf38300adae5899ef150f0ecce
    }
  }

  // Handle Entrance/Exit state resets or updates that don't need a full task
  if (shouldUpdateExit && now - exitOpenAt > 5000) {
    // Reset exit state in Firestore after 5s
    String url = firestoreBase + "/barrier/exit?updateMask.fieldPaths=isOpen&key=" + String(API_KEY);
    String body = "{\"fields\":{\"isOpen\":{\"booleanValue\":false}}}";
    HTTPClient http;
    http.begin(url);
    http.PATCH(body);
    http.end();
    shouldUpdateExit = false;
  }

  lastTaskRun = millis();
}

// ============================================================
// FIRESTORE TASK — runs on Core 0
// ============================================================
void firestoreTask(void* parameter) {
  unsigned long lastPush = 0;
  unsigned long lastPoll = 0;

  for (;;) {
    unsigned long now = millis();

    if (now - lastPush >= SLOT_PUSH_INTERVAL) {
      lastPush = now;
      pushSlotsToFirestore();
    }

    if (now - lastPoll >= FIRESTORE_POLL_INTERVAL) {
      lastPoll = now;
      pollFirestore();
    }

    vTaskDelay(100 / portTICK_PERIOD_MS);
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
    return; // Don't check for opening when already open
  }

  // ─── CHECK OPEN TRIGGER ───
  bool shouldOpen = false;
  String logAction = "";

  if (isEntrance) {
<<<<<<< HEAD
=======
    // 1. App reservation trigger
>>>>>>> 9ede775032aa32cf38300adae5899ef150f0ecce
    if (reservationTrigger) {
      Serial.println(">> App trigger detected!");
      shouldOpen = true;
      reservationTrigger = false;
      logAction = "Entrance opened by App";
    } 
    // 2. Autonomous walk-in (only if not full)
    else {
      int irState = digitalRead(irPin);
      if (irState == LOW) {
        if (isParkingFull()) {
          // Full — maybe show status on LCD
          lcd.setCursor(0, 1);
          lcd.print(" PARKING FULL!  ");
        } else {
          if (detectedAt == 0) detectedAt = millis();
          confirmCount++;
          if (confirmCount >= GATE_CONFIRM_NEEDED && millis() - detectedAt >= GATE_MIN_HOLD) {
            Serial.println(">> Walk-in — Entrance opening!");
            shouldOpen = true;
            logAction = "Entrance opened (Walk-in - Anonymous)";
          }
        }
      } else {
        confirmCount = 0;
        detectedAt = 0;
      }
    }
<<<<<<< HEAD

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
=======
  } else {
    // Exit — fully automatic
    int irState = digitalRead(irPin);
    if (irState == LOW) {
      if (detectedAt == 0) detectedAt = millis();
      confirmCount++;
      if (confirmCount >= GATE_CONFIRM_NEEDED && millis() - detectedAt >= GATE_MIN_HOLD) {
        Serial.println(">> Exit opening!");
        shouldOpen = true;
        logAction = "Exit opened (Automatic)";
      }
    } else {
      confirmCount = 0;
      detectedAt = 0;
    }
  }

  if (shouldOpen) {
    servo.write(openPos);
    openedAt = millis();
    isOpen = true;
>>>>>>> 9ede775032aa32cf38300adae5899ef150f0ecce
    confirmCount = 0;
    detectedAt = 0;
    clearAt = 0;
    if (isEntrance) showGateStatus(true, true);
    else {
      tripleBeep();
      // Update Exit status in Firestore
      shouldUpdateExit = true;
      exitOpenAt = millis();
      String url = firestoreBase + "/barrier/exit?updateMask.fieldPaths=isOpen&key=" + String(API_KEY);
      String body = "{\"fields\":{\"isOpen\":{\"booleanValue\":true}}}";
      HTTPClient http;
      http.begin(url);
      http.PATCH(body);
      http.end();
    }
    
    // Optional: Log to Firestore (Anonymous)
    if (logAction != "") pushLogToFirestore(logAction, "barrier");
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

  slotMutex = xSemaphoreCreateMutex();

  Wire.begin(25, 26);
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0); lcd.print("Welcome To      ");
  lcd.setCursor(0, 1); lcd.print("  E-Park Mo!    ");
  delay(5000);
  lcd.clear();

  for (int i = 0; i < 6; i++) pinMode(irPins[i], INPUT_PULLUP);
  pinMode(irEntrancePin, INPUT); // GPIO 34/35 don't support pullup
  pinMode(irExitPin,     INPUT);
  pinMode(buzzerPin, OUTPUT);
  buzzerOff();

  // ✅ LED pins — force LOW sa startup
  for (int i = 0; i < 6; i++) {
    gpio_set_direction((gpio_num_t)ledPins[i], GPIO_MODE_OUTPUT);
    gpio_set_level((gpio_num_t)ledPins[i], 0);
    pinMode(ledPins[i], OUTPUT);
  }

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

    xTaskCreatePinnedToCore(
      firestoreTask,
      "FirestoreTask",
      16384,
      NULL,
      1,
      NULL,
      0
    );

    Serial.println("Firestore task started on Core 0.");
  }
}

// ============================================================
// LOOP — runs on Core 1
// ============================================================
void loop() {
  unsigned long now = millis();

  // 1. Read IR sensors with debounce
  updateSlots();

<<<<<<< HEAD
  // 2. ✅ Update LEDs
  updateLEDs();
=======
  // 2. Run system tasks (polling/pushing) in non-blocking stages
  runSystemTasks();
>>>>>>> 9ede775032aa32cf38300adae5899ef150f0ecce

  // 3. Update LCD every 500ms
  if (now - lastLCDUpdate > 500) {
    lastLCDUpdate = now;
    updateLCD();
  }

  // 4. Debug print every 1s
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

  // 5. Gate handlers
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