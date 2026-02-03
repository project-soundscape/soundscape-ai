# Google Play Store Release Checklist

## Pre-Release Checklist

### 1. App Preparation ✅

- [x] App builds successfully (`flutter build appbundle --release`)
- [x] Signing key configured (`android/key.properties`)
- [x] App bundle generated (`build/app/outputs/bundle/release/app-release.aab`)
- [ ] Version number updated in `pubspec.yaml`
- [ ] Version code incremented for updates

### 2. Code Quality

- [ ] `flutter analyze` - No errors
- [ ] `flutter test` - All tests pass
- [ ] Remove debug prints and test code
- [ ] Check for hardcoded API keys/secrets
- [ ] ProGuard/R8 rules configured (if needed)

### 3. App Content

- [ ] App icon (512x512) ready
- [ ] Feature graphic (1024x500) ready
- [ ] Screenshots (min 2) captured
- [ ] Store listing text finalized
- [ ] Privacy policy URL live

---

## Google Play Console Setup

### 4. Developer Account

- [ ] Google Play Developer account active ($25 one-time fee)
- [ ] Account identity verified
- [ ] Payment profile set up (for monetization)

### 5. Create App

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **"Create app"**
3. Fill in:
   - App name: `SoundScape - Bird Sound ID`
   - Default language: `English (US)`
   - App or game: `App`
   - Free or paid: `Free`
4. Accept Developer Program Policies
5. Click **"Create app"**

### 6. Store Listing

Navigate to **Grow > Store presence > Main store listing**

#### App Details
- [ ] App name (30 chars max)
- [ ] Short description (80 chars max)
- [ ] Full description (4000 chars max)

#### Graphics
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG/JPEG)
- [ ] Phone screenshots (min 2, 1080x1920)
- [ ] Tablet screenshots (optional)

#### Categorization
- [ ] App category: `Education`
- [ ] Tags: Select relevant tags

---

## App Content & Policy

### 7. App Content (Policy Section)

Navigate to **Policy > App content**

#### Privacy Policy
- [ ] Privacy policy URL added
- [ ] URL must be publicly accessible

#### Ads Declaration
- [ ] Declare: App does NOT contain ads

#### App Access
- [ ] If login required: Provide test credentials
- [ ] Or select: All functionality available without login

#### Content Rating
- [ ] Complete IARC questionnaire
- [ ] Expected rating: `Everyone`

#### Target Audience
- [ ] Select target age groups
- [ ] App designed for: `General audience (13+)`

#### News Apps (if applicable)
- [ ] Not a news app

#### COVID-19 Apps (if applicable)
- [ ] Not a COVID-19 app

#### Data Safety
- [ ] Complete data collection survey
  - Location data: YES (GPS tagging)
  - Audio data: YES (recordings)
  - Personal info: YES (if using accounts)
- [ ] Data encryption: YES
- [ ] Data deletion: YES (users can delete)

#### Government Apps
- [ ] Not a government app

#### Financial Features
- [ ] No financial features

---

## Testing & Release

### 8. Internal Testing (Recommended First)

1. Navigate to **Release > Testing > Internal testing**
2. Click **"Create new release"**
3. Upload `app-release.aab`
4. Add release notes
5. Save and review
6. Add testers (up to 100 email addresses)
7. Start rollout

### 9. Closed Testing (Beta)

1. Navigate to **Release > Testing > Closed testing**
2. Create track or use default
3. Upload AAB
4. Add testers list
5. Review and release

### 10. Open Testing (Public Beta)

1. Navigate to **Release > Testing > Open testing**
2. Requires completed store listing
3. Upload AAB
4. Release to all users who opt-in

### 11. Production Release

1. Navigate to **Release > Production**
2. Click **"Create new release"**
3. Upload `app-release.aab`
4. Add release notes (What's new)
5. Review release
6. Select rollout percentage (start with 20% recommended)
7. Click **"Start rollout to Production"**

---

## Post-Release

### 12. Monitor & Respond

- [ ] Check for crashes in **Quality > Android vitals**
- [ ] Monitor reviews in **Ratings and reviews**
- [ ] Respond to user feedback
- [ ] Track installs in **Statistics**

### 13. Update Process

For future updates:
1. Increment `versionCode` in `pubspec.yaml`
2. Update `versionName` if significant changes
3. Build new AAB
4. Upload to Production
5. Add release notes
6. Roll out

---

## Quick Commands

```bash
# Build release bundle
flutter build appbundle --release

# Output location
build/app/outputs/bundle/release/app-release.aab

# Check bundle size
ls -lh build/app/outputs/bundle/release/app-release.aab

# Build APK (for direct distribution)
flutter build apk --release

# Clean and rebuild
flutter clean && flutter pub get && flutter build appbundle --release
```

---

## Important Links

| Resource | URL |
|----------|-----|
| Google Play Console | https://play.google.com/console |
| Developer Policy Center | https://play.google.com/about/developer-content-policy |
| Launch Checklist | https://developer.android.com/distribute/best-practices/launch/launch-checklist |
| App Bundle Guide | https://developer.android.com/guide/app-bundle |
| Content Rating | https://support.google.com/googleplay/android-developer/answer/9859655 |

---

## Troubleshooting

### Common Rejection Reasons

1. **Missing Privacy Policy**: Add valid URL
2. **Broken Screenshots**: Re-upload PNG/JPEG
3. **Misleading Description**: Match actual features
4. **Permission Issues**: Justify all permissions
5. **Intellectual Property**: Don't use trademarked names

### Upload Errors

- **AAB too large**: Enable app bundle (automatic splitting)
- **Signing error**: Verify keystore path and passwords
- **Version conflict**: Increment versionCode

---

## Timeline Estimate

| Step | Duration |
|------|----------|
| Store listing setup | 1-2 hours |
| App content/policy | 1-2 hours |
| Internal testing | 1-3 days |
| Review process | 1-7 days (varies) |
| Production rollout | Immediate after approval |

**Total**: ~1-2 weeks from submission to live
