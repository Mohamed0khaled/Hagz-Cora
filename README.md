# Hagz Kora - Football Booking App

A comprehensive Flutter application for organizing football matches with friends, inspired by WhatsApp's group chat UI but focused on match bookings and team management.

## Features

### Core Features
- **User Authentication**: Email/password and Google Sign-in with Firebase
- **Friend Management**: Add friends, send/receive friend requests
- **Group-based Bookings**: Create and manage football match groups
- **Real-time Chat**: WhatsApp-style group chat for each match
- **Live Formation Management**: Interactive drag-and-drop football pitch
- **Dual Admin Support**: Two team captains can manage their teams independently
- **Push Notifications**: FCM integration for real-time updates
- **Automatic Cleanup**: Expired matches are automatically removed

### Advanced Features
- **Team Assignment**: Players can be assigned to Team A or Team B
- **Formation Tactics**: Multiple formation types (4-4-2, 4-3-3, 3-5-2, etc.)
- **Match Scheduling**: Date/time selection with stadium details
- **Notification Settings**: Granular control over push notifications
- **Multi-language Support**: English and Arabic (coming soon)
- **Dark/Light Theme**: System-adaptive theming

## Architecture

### Tech Stack
- **Framework**: Flutter 3.x
- **State Management**: GetX + Provider
- **Backend**: Firebase (Auth, Firestore, FCM, Storage)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Navigation**: GetX Navigation 2.0

### Project Structure
```
lib/
├── constants/           # App constants, colors, themes
├── controllers/         # GetX controllers (business logic)
├── models/             # Data models
├── services/           # Firebase and API services
├── utils/              # Utility functions and helpers
├── views/              # UI screens and widgets
│   ├── auth/           # Authentication screens
│   ├── booking/        # Match booking and group management
│   ├── formation/      # Formation and tactics screens
│   ├── friends/        # Friend management
│   ├── main/           # Main navigation and home
│   ├── profile/        # User profile management
│   └── settings/       # App settings and preferences
├── widgets/            # Reusable UI components
└── main.dart           # App entry point
```

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Firebase project setup
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd hagzcoora
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication (Email/Password and Google)
   - Create Firestore database
   - Enable Cloud Messaging
   - Download and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

4. **Run the app**
   ```bash
   flutter run
   ```

### Environment Setup

Create a `.env` file in the root directory:
```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
FIREBASE_APP_ID=your-app-id
```

## Core Features Guide

### Authentication Flow
1. **Splash Screen**: Initial loading and auth state check
2. **Auth Screen**: Login/Register with email or Google
3. **Profile Setup**: Complete user profile after registration
4. **Main App**: Access to all features after authentication

### Booking Flow
1. **Create Match**: Set date, time, match type, and stadium
2. **Invite Friends**: Add friends to your match group
3. **Team Assignment**: Assign players to teams (dual admin mode)
4. **Group Chat**: Communicate with all match participants
5. **Formation**: Set up team formations and tactics
6. **Match Day**: Real-time updates and notifications

### Friend Management
1. **Search Users**: Find friends by username or email
2. **Send Requests**: Send friend requests to other users
3. **Manage Requests**: Accept/decline incoming requests
4. **Friend List**: View and manage your friends

## Key Components

### Models
- **UserModel**: User data and authentication state
- **BookingGroup**: Match groups with participants and settings
- **Formation**: Team formations with player positions
- **ChatMessage**: Real-time messaging data
- **FriendRequest**: Friend relationship management

### Controllers
- **AuthController**: Authentication and user management
- **BookingController**: Match booking and group management
- **FriendController**: Friend relationships and requests

### Services
- **AuthService**: Firebase Authentication integration
- **BookingService**: Firestore operations for matches
- **FriendService**: Friend management operations
- **NotificationService**: FCM and local notifications

## Firebase Structure

### Collections
```
users/
├── {userId}/
│   ├── email, username, displayName
│   ├── profilePictureUrl, isActive
│   ├── friendIds[], pendingFriendRequests[]
│   └── sentFriendRequests[]

groups/
├── {groupId}/
│   ├── name, adminId, opponentAdminId
│   ├── matchType, bookingType, matchDate
│   ├── playerIds[], teamAPlayerIds[], teamBPlayerIds[]
│   ├── formation{}, members[]
│   └── isActive, createdAt

messages/
├── {groupId}/
│   └── messages/
│       ├── {messageId}/
│       │   ├── senderId, senderName, content
│       │   ├── type, timestamp
│       │   └── readBy[]

formations/
├── {groupId}/
│   ├── type, playerPositions{}
│   ├── lastUpdated, lastUpdatedBy
│   └── teamAPositions[], teamBPositions[]
```

## Notifications

### Push Notification Types
- **Friend Requests**: New friend request received
- **Group Invites**: Invited to a match group
- **Match Reminders**: Upcoming match notifications
- **Chat Messages**: New messages in group chat
- **Formation Updates**: Team formation changes

### Local Notifications
- **Match Reminders**: Scheduled 1 hour before match
- **Daily Summaries**: Daily activity recap
- **Achievement Unlocks**: User milestones

## UI/UX Design

### Theme
- **Primary Color**: WhatsApp Green (#25D366)
- **Secondary Colors**: Team colors (Blue/Red) for dual teams
- **Football Theme**: Pitch green, grass textures, football icons
- **Typography**: Clean, readable fonts with proper hierarchy

### Responsive Design
- **Mobile First**: Optimized for smartphone use
- **Adaptive Layouts**: Works on various screen sizes
- **Accessibility**: WCAG compliance and screen reader support

## Testing

Run tests with:
```bash
flutter test
```

### Test Coverage
- Unit tests for models and services
- Widget tests for UI components
- Integration tests for complete flows

## Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Email: support@hagzkora.com
- Issues: GitHub Issues page
- Documentation: Project Wiki

## Roadmap

### Upcoming Features
- [ ] Video calls integration
- [ ] Match statistics and analytics
- [ ] Tournament mode
- [ ] Stadium booking integration
- [ ] Payment integration
- [ ] Social media sharing
- [ ] Advanced analytics dashboard
- [ ] Coach mode with tactical analysis

---

Built with ❤️ using Flutter and Firebase
