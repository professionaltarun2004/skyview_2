# SkyView - AI-Powered Flight Booking App

SkyView is a modern flight booking application that combines the power of AI, voice assistance, and real-time navigation to provide a seamless travel booking experience.

## Features

- 🎯 Smart Flight Search
- 🤖 AI Chat Assistant (Powered by Gemini)
- 🗣️ Voice Commands
- 🗺️ Real-time Navigation
- 🔐 Secure Authentication
- 💳 Payment Integration
- 📱 Cross-platform Support

## Prerequisites

- Flutter SDK (>=3.0.0)
- Python 3.8+
- Firebase Account
- Google Cloud Account (for Gemini AI)
- Razorpay Account (for payments)

## Setup Instructions

### 1. Frontend (Flutter)

1. Clone the repository:
```bash
git clone https://github.com/yourusername/skyview.git
cd skyview
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a new Firebase project
   - Add Android and iOS apps in Firebase console
   - Download and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Run `flutterfire configure` to set up Firebase

4. Configure environment variables:
   - Create `.env` file in the root directory
   - Add required API keys and configuration

5. Run the app:
```bash
flutter run
```

### 2. Backend (Python/FastAPI)

1. Create and activate virtual environment:
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Configure environment variables:
   - Copy `.env.example` to `.env`
   - Add required API keys and configuration

4. Run the backend:
```bash
python run.py
```

## Deployment

### Frontend Deployment

1. Build the app:
```bash
flutter build apk  # For Android
flutter build ios  # For iOS
```

2. Deploy to Firebase Hosting:
```bash
firebase deploy --only hosting
```

### Backend Deployment

1. Deploy to Firebase Functions:
```bash
firebase deploy --only functions
```

2. Or deploy to Render/Fly.io:
   - Create a new service
   - Connect your repository
   - Set environment variables
   - Deploy

## Environment Variables

### Frontend (.env)
```
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_AUTH_DOMAIN=your_firebase_auth_domain
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_STORAGE_BUCKET=your_firebase_storage_bucket
FIREBASE_MESSAGING_SENDER_ID=your_firebase_messaging_sender_id
FIREBASE_APP_ID=your_firebase_app_id
RAZORPAY_KEY_ID=your_razorpay_key_id
```

### Backend (.env)
```
GOOGLE_API_KEY=your_gemini_api_key
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_PRIVATE_KEY=your_firebase_private_key
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
API_KEY=your_backend_api_key
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, email support@skyview.com or join our Slack channel.
