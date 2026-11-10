# Study Buddy iOS wrapper

A minimal iOS 15+ WKWebView app that loads the existing hosted Study Buddy website at `https://mindpulse.ai.studio/`.

## Build an IPA on GitHub Actions

1. Create a GitHub repository and upload these files to its `main` branch.
2. For free, unlimited standard macOS Actions minutes, make the repository public. The wrapper contains no API keys or backend secrets; it only contains the public website URL. If you prefer a private repository, GitHub Free includes a limited monthly Actions allowance and macOS usage consumes it faster.
3. Open the repository's **Actions** tab and run **Build Study Buddy IPA** (or push a commit to `main`).
4. When the workflow finishes, open the run and download the `StudyBuddy-IPA` artifact.
5. Extract `StudyBuddy.ipa` and transfer it to the iPhone, then open it in TrollStore to install.

## Notes

- Bundle ID: `com.lkgeek.studybuddy`
- Minimum iOS: 15.0
- Device architecture: arm64 (iPhone 7 Plus supported)
- The app is built without a paid Apple Developer signing identity for TrollStore installation.
- This wrapper does not include the website or API keys. It loads the hosted website at runtime.
- Camera/microphone capture is granted at the WebKit layer when the website requests it; iOS may still show system permission prompts. Test voice and file-upload features on-device.
- This is the first build scaffold. It has not yet been compiled on an Apple/Xcode runner in this environment.
