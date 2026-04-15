# Collaboration Guide

Welcome to the project! To maintain security, we do not upload API keys or sensitive configurations to GitHub. Follow these steps to set up your local environment.

## 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js](https://nodejs.org/) (for the backend)
- [MongoDB](https://www.mongodb.com/) (local or Altas)

## 2. Environment Setup

### Backend
1. Navigate to the `backend/` directory.
2. Create a file named `.env` by copying `.env.example`:
   ```bash
   cp .env.example .env
   ```
3. Ask the project owner for the actual values for `MONGO_URI` and `GEMINI_API_KEY`, or use your own.
4. The project also requires a Firebase Service Account key. Ask the owner for `serviceAccountKey.json` and place it in the `backend/` directory.

### Flutter App
The Firebase project is already configured in `lib/firebase_options.dart`. If you need to use a different Firebase project, you will need to re-initialize it using the FlutterFire CLI.

## 3. Running the Project

### Start Backend
```bash
cd backend
npm install
npm start
```

### Run Flutter App
```bash
flutter pub get
flutter run
```

---
**Security Note:** Never commit your `.env` or `serviceAccountKey.json` files. They are ignored by Git for your protection.
