# Kids Task Tracker

A cross-platform mobile application built with Flutter and Firebase to help families manage tasks and rewards for children.

## 📋 Project Overview

**Kids Task Tracker** is a gamified task management app designed for families with children aged 7+. It uses Kanban boards, reward systems, and automation to motivate children to complete chores, homework, and other responsibilities.

## 🎯 Key Features

### For Parents
- Create and manage tasks with customizable rewards
- Set up multiple Kanban boards for different categories (chores, homework, sports, etc.)
- Track children's progress and statistics
- Configure automated workflows and notifications
- Manage multiple children (up to 10 in Premium)

### For Children
- View assigned tasks on colorful Kanban boards
- Move tasks through workflow stages
- Earn points and badges for completed tasks
- Redeem points for rewards set by parents
- Track achievements and progress

## 🏗️ Architecture

This project follows **Clean Architecture** principles with the following structure:

```
lib/
├── core/                    # Core utilities, constants, theme
│   ├── constants/           # App-wide constants
│   ├── error/               # Exception and failure classes
│   ├── network/             # Firebase and API services
│   ├── routing/             # Navigation configuration
│   ├── theme/               # Theme and styling
│   └── utils/               # Utility functions
├── data/                    # Data layer
│   ├── local/               # Local storage (Hive, SharedPreferences)
│   ├── models/              # Data models with serialization
│   ├── remote/              # Firebase data sources
│   └── repositories/        # Repository implementations
├── domain/                  # Business logic layer
│   ├── entities/            # Business entities
│   ├── repositories/        # Repository interfaces
│   └── usecases/            # Business use cases
├── features/                # Feature modules
│   ├── auth/                # Authentication feature
│   ├── tasks/               # Task management
│   ├── kanban/              # Kanban boards
│   ├── rewards/             # Rewards and badges
│   ├── profile/             # User profiles
│   └── settings/            # App settings
├── presentation/            # UI layer
│   ├── providers/           # Riverpod state management
│   ├── screens/             # Screen widgets
│   └── widgets/             # Reusable widgets
└── main.dart                # App entry point
```

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.x
- **State Management**: Riverpod
- **Backend**: Firebase
  - Authentication
  - Firestore (Database)
  - Cloud Storage
  - Cloud Functions
- **Navigation**: GoRouter
- **Local Storage**: Hive, SharedPreferences

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.5.0 or higher
- Dart 3.5.0 or higher
- Firebase project setup
- Android Studio / VS Code

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd kids_task_tracker
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add your platform (iOS/Android/Web)
   - Download and place configuration files:
     - `google-services.json` (Android)
     - `GoogleService-Info.plist` (iOS)
   - Enable Authentication (Email/Password)
   - Create Firestore database
   - Set up Security Rules

4. Run the app:
```bash
flutter run
```

## 📱 User Roles

### Parent
- Full access to all features
- Can create/manage up to 10 children (Free: 3)
- Creates tasks, rewards, and boards
- Views statistics and analytics

### Child
- Limited interface optimized for ages 7+
- Can view and interact with assigned tasks
- Earns and redeems rewards
- Cannot modify settings or create tasks

## 💎 Monetization

### Free Tier
- Up to 3 children
- 1 Kanban board
- Up to 20 active tasks
- Basic rewards system
- Standard notifications

### Premium Tier
- Up to 10 children
- Unlimited boards and tasks
- Custom rewards creation
- API integrations
- Advanced automation (Robots)
- Priority support

## 🔐 Security

- Firebase Authentication for user management
- Firestore Security Rules for data protection
- Role-based access control
- Data isolation between families
- COPPA and GDPR compliant

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## 📞 Support

For questions and support:
- GitHub Issues
- Email: support@kidstracker.com
- Documentation: [Link to docs]

---

**Version**: 1.0.0  
**Last Updated**: 2026-01-07
