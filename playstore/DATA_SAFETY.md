# Google Play Data Safety Form Answers

Use these answers when filling out the Data Safety section in Google Play Console.

---

## Overview Questions

### Does your app collect or share any of the required user data types?
**Answer**: Yes

### Is all of the user data collected by your app encrypted in transit?
**Answer**: Yes

### Do you provide a way for users to request that their data is deleted?
**Answer**: Yes

---

## Data Types Collected

### 1. Location

| Question | Answer |
|----------|--------|
| **Is this data collected, shared, or both?** | Collected |
| **Is this data processed ephemerally?** | No |
| **Is this data required or optional?** | Optional (app works without it) |
| **Why is this data collected?** | App functionality |

**Details**: Approximate and precise location used to tag bird recordings with geographic coordinates for mapping features.

---

### 2. Audio

| Question | Answer |
|----------|--------|
| **Is this data collected, shared, or both?** | Collected |
| **Is this data processed ephemerally?** | No |
| **Is this data required or optional?** | Required for core functionality |
| **Why is this data collected?** | App functionality |

**Details**: Voice or sound recordings (bird sounds) used for AI-powered species identification. Recordings stored locally and optionally synced to cloud.

---

### 3. Personal Info (Email - if using accounts)

| Question | Answer |
|----------|--------|
| **Is this data collected, shared, or both?** | Collected |
| **Is this data processed ephemerally?** | No |
| **Is this data required or optional?** | Optional (only if creating account) |
| **Why is this data collected?** | Account management |

**Details**: Email address collected only when user creates optional account for cloud sync.

---

### 4. App Activity

| Question | Answer |
|----------|--------|
| **Is this data collected, shared, or both?** | Collected |
| **Is this data processed ephemerally?** | Yes |
| **Is this data required or optional?** | Optional |
| **Why is this data collected?** | Analytics, App functionality |

**Details**: In-app interactions used to improve app experience.

---

### 5. Device or Other IDs

| Question | Answer |
|----------|--------|
| **Is this data collected, shared, or both?** | Collected |
| **Is this data processed ephemerally?** | Yes |
| **Is this data required or optional?** | Optional |
| **Why is this data collected?** | App functionality |

**Details**: Device identifiers used for anonymous analytics only.

---

## Data NOT Collected

Check these as NOT collected:
- [ ] Financial info
- [ ] Health and fitness
- [ ] Messages
- [ ] Photos and videos (separate from audio)
- [ ] Contacts
- [ ] Calendar
- [ ] Browsing history
- [ ] Search history
- [ ] Installed apps
- [ ] Files and docs

---

## Security Practices

### Is all collected data encrypted in transit?
**Answer**: Yes

### Can users request data deletion?
**Answer**: Yes

### How can users request deletion?
**Answer**: 
- In-app: Settings > Delete Account
- Email: privacy@soundscape.app
- Response time: Within 30 days

---

## Data Handling Summary for Store Listing

```
📍 Location
• Collected for mapping bird sightings
• Not shared with third parties

🎤 Audio  
• Bird sound recordings for species ID
• Stored locally and optionally in cloud
• Not shared with third parties

📧 Email (Optional)
• Only if creating account
• Used for cloud sync only
• Not shared with third parties

🔒 Security
• All data encrypted in transit
• Users can delete data anytime
```

---

## Common Questions

**Q: Why does the app need location?**
A: To tag recordings with GPS coordinates, enabling the map feature to show where birds were recorded.

**Q: Why does the app need microphone access?**
A: Core functionality - recording bird sounds for AI identification.

**Q: Is my voice recorded?**
A: The app includes speech detection. If human speech is detected, you're notified. Recordings are primarily for bird sounds.

**Q: Can I use the app without an account?**
A: Yes, full functionality available offline without an account.

**Q: How do I delete my data?**
A: Delete individual recordings in the Library, or delete your account in Settings to remove all cloud data.

---

## Notes for Submission

1. Be consistent between Privacy Policy and Data Safety form
2. Update Data Safety if adding new data collection features
3. Review annually for accuracy
4. Users can see this info on your Play Store listing
