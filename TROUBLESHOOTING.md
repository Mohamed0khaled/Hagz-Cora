# Troubleshooting Guide

## Common Issues and Solutions

### 1. "Document was not found" Error

**Problem**: You're getting an error like `[cloud_firestore/not-found] Some requested document was not found.`

**Solution**: This has been fixed in the latest code. The app now automatically creates user profiles if they don't exist. If you're still experiencing this:

1. Sign out completely from the app
2. Clear app data (or reinstall the app)
3. Sign in again with Google

**Root Cause**: This happens when a user signs in successfully but their profile document wasn't created in Firestore properly.

### 2. Google Sign-In Not Working

**Common Causes**:
- SHA-1 fingerprint not added to Firebase project
- Wrong google-services.json file
- Google Sign-In not enabled in Firebase Authentication

**Solutions**:
1. Check Firebase Console → Authentication → Sign-in method → Google (should be enabled)
2. Verify SHA-1 fingerprint in Firebase Console → Project Settings → General
3. Ensure `google-services.json` is in `android/app/` directory
4. For iOS, ensure `GoogleService-Info.plist` is properly configured

### 3. Image Upload Failures

**Common Issues**:
- Image too large (>5MB)
- Network connectivity issues
- Firebase Storage rules not configured

**Solutions**:
1. Check image size before upload
2. Verify internet connection
3. Check Firebase Storage rules (see AUTHENTICATION_README.md)

### 4. Profile Updates Not Saving

**Possible Causes**:
- Firestore security rules blocking writes
- User not properly authenticated
- Network issues

**Solutions**:
1. Check Firestore rules (see AUTHENTICATION_README.md)
2. Try signing out and signing back in
3. Check internet connection

## Getting Debug Information

To get more detailed error information, check the Flutter logs:

```bash
flutter logs
```

Look for error messages from:
- `AuthService`
- `DatabaseService` 
- `AuthProvider`

## Firebase Console Checks

1. **Authentication**: Check if users appear in Authentication → Users
2. **Firestore**: Check if user documents exist in Database → users collection
3. **Storage**: Check if profile images are uploaded to profile_images folder

## Contact Support

If issues persist:
1. Check Firebase Console for error logs
2. Verify all configuration files are properly placed
3. Ensure security rules are correctly set up
4. Check network connectivity

The authentication system is designed to be robust and self-healing, automatically creating missing user profiles and handling most edge cases gracefully.
