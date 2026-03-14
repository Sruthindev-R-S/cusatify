# CUSAT Smart Campus  
### Digital Library Seat Management System

---

## 📌 Project Overview

CUSAT Smart Campus is a Flutter-based mobile application designed to optimize library seat management at Cochin University of Science and Technology (CUSAT).

The application enables students to scan a QR code inside the library, reserve available seats, and automatically start a timed session. Once the session expires, the system automatically checks out the student and releases the seat.

This ensures fair usage, prevents seat blocking, and improves overall resource efficiency.

---

## 🎯 Objectives

- Ensure fair and transparent seat allocation  
- Prevent long-duration seat blocking  
- Enable real-time seat availability tracking  
- Automate seat checkout after usage  
- Digitally streamline campus resource management  

---

## 👥 User Roles

### 🎓 Student
- Secure login authentication  
- Access personalized dashboard  
- Scan QR code inside library  
- View real-time available seats  
- Select and reserve a seat  
- Automatic timer activation  
- Auto checkout when timer expires  

### 👨‍🏫 Faculty
- Secure login  
- Access faculty dashboard  
- Future scope: Monitoring and administrative controls  

---

## ✨ Core Features

- Role-based authentication (Student / Faculty)
- QR code–based library verification
- Real-time seat availability system
- Automated timer-based seat allocation
- Automatic seat release after timer expiry
- Secure backend integration using Firebase

---

## ⚙️ System Workflow

1. User logs into the application  
2. Navigates to the Library section  
3. Scans the QR code placed inside the library  
4. Available seats are fetched from the database  
5. User selects a seat  
6. Timer starts automatically  
7. On timer expiry:
   - User is automatically checked out  
   - Seat status is updated to available  

---

## 🛠️ Technology Stack

### Frontend
- Flutter  
- Dart  

### Backend
- Supabase

### Integrations
- QR Code Scanner Package  
- Session & Timer Management Logic  

---

How to run this project:
-git clone github.com/Sruthindev-R-S/cusatify
Go to project Root,Requires flutter and dart download and setup it
-To download dependencies: flutter pub get
Select device and Run using :flutter run

