# Learning Management System

A cross-platform Flutter application for managing classes, sharing learning resources, communicating with classmates, and creating and evaluating quizzes.

## Features

- **Authentication**
  - Firebase Authentication
  - Google Sign-In
  - Authentication-aware routing that redirects unauthenticated users to the login screen

- **Classroom management**
  - Browse and open classes from the home screen
  - View class details, creator information, and the class ID
  - Copy a class ID to the clipboard
  - Creator-aware controls for managing class content

- **Learning resources**
  - Upload notes and other files to Firebase Storage
  - Store resource metadata in Cloud Firestore
  - Add and watch YouTube learning videos
  - View PDFs, images, and office documents in the app
  - Download or open supported resources through platform integrations

- **Quizzes and assessments**
  - Create quizzes and questions
  - Support for multiple-choice, multiple-select, short-answer, numerical, and long-answer question types
  - Configure quiz visibility and scheduled availability
  - Automatically score supported question types
  - Review and manually evaluate student submissions

- **Class communication**
  - Chat within a class
  - View videos and notes, quizzes, and chat from separate class-detail tabs

- **Application experience**
  - Material 3 interface with an orange color theme
  - Named navigation with `go_router`
  - Shared application state with `Provider`
  - Loading feedback with `flutter_easyloading`
  - About and settings pages

## Project structure

The main application code is organized under `lib/`:

```text
lib/
├── auth/
│   └── login_page.dart               # Firebase and Google sign-in UI
├── database_helpers/
│   ├── db_helper.dart                # Firebase Storage and Firestore operations
│   └── supabase_db_helper.dart       # Supabase helper prototype
├── file_viewers/
│   ├── image_preview_screen.dart     # Image preview
│   ├── office_web_viewer.dart        # Office document viewer
│   └── pdf_viewer.dart               # PDF viewer
├── pages/
│   ├── home_page.dart                # Class list and home screen
│   ├── class_detail_page.dart        # Class overview and tab navigation
│   ├── videos_and_notes_tab.dart     # Learning resources
│   ├── upload_tab.dart               # Upload entry point
│   ├── upload_videos_and_notes.dart  # Resource upload workflow
│   ├── quiz_tab.dart                 # Quiz list and visibility controls
│   ├── add_quiz_page.dart            # Quiz creation
│   ├── quiz_detail_page.dart         # Quiz details
│   ├── quiz_submission_page.dart     # Quiz submission workflow
│   ├── submission_detail_page.dart   # Submission review and grading
│   ├── chat_tab.dart                 # Class chat
│   ├── about_page.dart               # About screen
│   └── settings_page.dart            # Settings screen
├── providers/
│   └── app_data_provider.dart        # Shared application state
├── services/
│   └── firebase_options.dart         # Generated Firebase configuration
└── main.dart                         # App initialization and routing
```

## Technology stack

- Flutter and Dart
- Firebase Core and Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Google Sign-In
- Supabase Flutter integration
- Provider for state management
- GoRouter for navigation
- YouTube Player Flutter
- PDF and in-app web viewers

## Getting started

### Prerequisites

- Flutter SDK compatible with Dart SDK `^3.6.0`
- Android Studio or Xcode, depending on the target platform
- A configured Firebase project with Authentication, Cloud Firestore, and Storage enabled
- Google Sign-In configured for the target platforms

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/HrishikeshWadile/learning_management_system.git
   cd learning_management_system
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Configure Firebase for the platforms you want to run. Keep generated Firebase configuration files and service credentials out of public repositories when appropriate.

4. Run the application:

   ```bash
   flutter run
   ```

## Configuration and security

The application uses Firebase and Supabase services. Before deploying, review the service configuration and move environment-specific values and credentials into a secure configuration process. Do not commit private keys, service-account credentials, or unrestricted production secrets.

Also configure Firebase Security Rules for class data, uploads, quizzes, and submissions before using the application with real users.

## Useful commands

```bash
flutter analyze
flutter test
flutter run
```

## Resources

- [Flutter documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Cloud Firestore documentation](https://firebase.google.com/docs/firestore)
