# CUSAT Smart Campus

## Digital Library Seat Management System

## Project Overview

CUSAT Smart Campus is a Flutter-based mobile application designed to improve library seat management at Cochin University of Science and Technology (CUSAT).

The application allows students to scan a QR code inside the library, view available seats in real time, and reserve a seat for a limited duration. When the session timer expires, the system automatically checks out the student and releases the seat so that others can use it.

This system helps prevent seat blocking and ensures fair usage of library resources.

---

## Objectives

* Ensure fair and transparent seat allocation
* Prevent long-duration seat blocking
* Provide real-time seat availability tracking
* Automate seat checkout after usage
* Digitize campus resource management

---

## User Roles

### Student

* Secure login authentication
* Access personal dashboard
* Scan QR code inside the library
* View available seats in real time
* Select and reserve a seat
* Automatic session timer
* Auto checkout when timer expires

### Faculty

* Secure login authentication
* Access faculty dashboard
* Future scope: monitoring and administrative controls

---

## Core Features

* Role-based authentication (Student / Faculty)
* QR code-based library verification
* Real-time seat availability
* Automated timer-based seat allocation
* Automatic seat release after session expiry
* Secure backend integration using Supabase

---

## System Workflow

1. User logs into the application
2. User navigates to the library section
3. User scans the QR code placed inside the library
4. Application retrieves available seats from the database
5. User selects a seat
6. A timer automatically starts
7. When the timer expires:

   * The user is automatically checked out
   * The seat status is updated to available

---

## Technology Stack

### Frontend

* Flutter
* Dart

### Backend

* Supabase

### Integrations

* QR Code Scanner package
* Session and timer management logic

---

## Installation

### Clone the repository

```
git clone https://github.com/Sruthindev-R-S/cusatify.git
```

### Navigate to project directory

```
cd cusatify
```

### Install dependencies

```
flutter pub get
```

### Run the project

```
flutter run
```

---

## Requirements

* Flutter SDK
* Dart SDK
* Android Studio or VS Code
* Android emulator or physical device

---

## Future Improvements

* Admin dashboard for library monitoring
* Seat usage analytics
* Push notifications for session expiry
* Multi-library support

---

