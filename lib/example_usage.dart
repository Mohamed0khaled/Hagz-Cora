// Example usage of the authentication flow

/*
To use the Google Sign-In authentication flow in your Flutter app:

1. Setup Firebase Project:
   - Go to https://console.firebase.google.com/
   - Create a new project or use existing one
   - Enable Authentication and add Google Sign-In as provider
   - Enable Firestore Database
   - Enable Firebase Storage
   - Download and configure google-services.json (Android) and GoogleService-Info.plist (iOS)

2. Configure Google Sign-In:
   - Add your app's SHA-1 fingerprint to Firebase project settings
   - For iOS, add URL schemes to Info.plist

3. Firestore Security Rules:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users can read and write their own user document
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

4. Firebase Storage Security Rules:
   ```
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       // Users can upload and read their own profile images
       match /profile_images/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

5. Usage in your app:
   The authentication flow is already integrated in main.dart.
   When users open the app:
   - If not authenticated: Shows LoginScreen with Google Sign-In button
   - If authenticated: Shows HomePage with access to ProfileSettingsScreen

6. Key Features:
   - Google Sign-In integration
   - Automatic user profile creation in Firestore
   - Profile picture upload to Firebase Storage
   - Clean error handling
   - Real-time auth state management
   - Secure sign-out and account deletion

7. Customization:
   - Update app colors in utils/constants.dart
   - Modify UI components in screens/
   - Add more authentication providers in services/auth_service.dart
   - Extend user model in models/user_model.dart
*/
