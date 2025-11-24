# RAG Mobile - iOS App Setup Guide

Complete guide to setting up your first Hotwire Native iOS app. This will display your Rails dashboard in a native iOS app!

## Prerequisites

- ✅ Xcode installed (you have this!)
- ✅ Rails server (your existing app)
- ✅ Physical iPhone (optional, for device testing)

## Part 1: Create Xcode Project (10 minutes)

### Step 1: Open Xcode

1. Open **Xcode** from your Applications folder
2. You'll see the welcome screen

### Step 2: Create New Project

1. Click **"Create a new Xcode project"**
2. Choose **iOS** tab at the top
3. Select **"App"** template
4. Click **"Next"**

### Step 3: Configure Project

Fill in these details:
- **Product Name**: `RAG Mobile`
- **Team**: Select your Apple ID (or "None" for simulator only)
- **Organization Identifier**: `com.yourname.ragmobile` (use your name)
- **Bundle Identifier**: (auto-generated, e.g., `com.yourname.ragmobile.RAG-Mobile`)
- **Interface**: Select **"Storyboard"**
- **Language**: Select **"Swift"**
- **Storage**: **Uncheck** "Use Core Data"
- **Tests**: **Uncheck** both test options (not needed for now)

Click **"Next"**

### Step 4: Choose Location

1. Navigate to your project folder: `/Users/pawelski/Projects/AI/rag-system/rag-web/ios-app`
2. **Uncheck** "Create Git repository"
3. Click **"Create"**

Xcode will create the project and open it!

## Part 2: Add Turbo iOS Framework (5 minutes)

### Step 1: Add Swift Package

1. In Xcode, go to menu: **File → Add Package Dependencies...**
2. In the search box (top right), paste: `https://github.com/hotwired/turbo-ios`
3. Press Enter/Return
4. You'll see "turbo-ios" appear in the list
5. For "Dependency Rule", select **"Up to Next Major Version"** (should show "7.0.0 < 8.0.0")
6. Click **"Add Package"**
7. In the next dialog, make sure "Turbo" is checked
8. Click **"Add Package"**

Wait a few seconds for Xcode to download the package.

### Step 2: Verify Installation

1. In the left sidebar (Project Navigator), expand your project
2. Look for "Package Dependencies" section
3. You should see "turbo-ios" listed

## Part 3: Add Your Swift Files (10 minutes)

### Step 1: Delete Template Files

In the Project Navigator (left sidebar):
1. Find `ViewController.swift` (the default file)
2. Right-click → **"Delete"**
3. Choose **"Move to Trash"**

### Step 2: Add Your Swift Files

You have 3 Swift files in the `ios-app` directory. For each file:

1. In Xcode, right-click your project folder (blue icon)
2. Select **"Add Files to 'RAG Mobile'..."**
3. Navigate to: `/Users/pawelski/Projects/AI/rag-system/rag-web/ios-app`
4. Select the file (don't select the folder!)
5. Make sure **"Copy items if needed"** is **CHECKED**
6. Make sure your target is **CHECKED** under "Add to targets"
7. Click **"Add"**

Add these files in this order:
- `Configuration.swift`
- `SceneDelegate.swift`
- `WebViewController.swift`

### Step 3: Update SceneDelegate Reference

1. In Project Navigator, click on **"SceneDelegate.swift"** (the OLD one that came with template)
2. If it exists, delete it (Move to Trash)
3. Your new SceneDelegate.swift should be the only one

## Part 4: Configure Info.plist (5 minutes)

### Step 1: Open Info.plist

1. In Project Navigator, click **"Info.plist"**
2. You'll see a list of keys and values

### Step 2: Add HTTP Exception for Localhost

1. Right-click in the Info.plist editor → **"Add Row"**
2. Type: `NSAppTransportSecurity`
3. It will auto-complete - press Enter
4. Click the disclosure triangle (▸) to expand
5. Hover over the row, click the **"+"** button
6. Add key: `NSAllowsLocalNetworking`
7. Change Type to **Boolean**, Value to **YES**
8. Hover over `NSAppTransportSecurity` again, click **"+"**
9. Add key: `NSExceptionDomains`
10. Expand it, click **"+"**
11. Add key: `localhost`
12. Expand localhost, click **"+"**
13. Add key: `NSExceptionAllowsInsecureHTTPLoads`
14. Change Type to **Boolean**, Value to **YES**

### Step 3: Add Local Network Description

1. Right-click in Info.plist → **"Add Row"**
2. Type: `NSLocalNetworkUsageDescription`
3. Set Value to: `This app connects to your local development server`

### Step 4: Update Scene Configuration

1. Find `UIApplicationSceneManifest` (should already exist)
2. Expand it → `UISceneConfigurations` → `UIWindowSceneSessionRoleApplication`
3. Expand the first item (Array item 0)
4. Find `UISceneDelegateClassName`
5. Change its value to: `$(PRODUCT_MODULE_NAME).SceneDelegate`

## Part 5: Update Configuration (2 minutes)

### For Simulator Testing (localhost)

The default configuration in `Configuration.swift` is already set to `http://localhost:3000` - no changes needed!

### For Physical iPhone Testing

1. Open `Configuration.swift` in Xcode
2. Find your Mac's IP address:
   - Open Terminal
   - Run: `ifconfig | grep "inet " | grep -v 127.0.0.1`
   - Look for something like: `inet 192.168.1.100` (your IP will be different)
3. Update the baseURL:
   ```swift
   static let baseURL = URL(string: "http://192.168.1.100:3000")!
   ```
   Replace `192.168.1.100` with YOUR Mac's IP address

## Part 6: Test in Simulator (5 minutes)

### Step 1: Start Rails Server

In Terminal:
```bash
cd /Users/pawelski/Projects/AI/rag-system/rag-web
bin/rails server
```

Wait until you see: `Listening on http://127.0.0.1:3000`

### Step 2: Run iOS App

1. In Xcode, at the top, click the device selector (next to "RAG Mobile")
2. Choose **"iPhone 15 Pro"** (or any iPhone simulator)
3. Click the **▶ Play button** (or press Cmd+R)

Xcode will:
- Build the app (15-30 seconds first time)
- Launch the simulator
- Install and run your app

### Step 3: What You Should See

✅ iOS Simulator opens
✅ Your app launches
✅ You see your Rails dashboard!
✅ You can tap links and navigate
✅ Native back button works in navigation bar

### Troubleshooting Simulator

If you see "Connection Error":
- ✅ Is Rails server running? Check Terminal
- ✅ Does `http://localhost:3000` work in Safari?
- ✅ Check Configuration.swift has correct URL

## Part 7: Test on Physical iPhone (10 minutes)

### Step 1: Connect iPhone

1. Connect your iPhone to Mac with USB cable
2. On iPhone, if prompted, tap **"Trust This Computer"**
3. In Xcode, the device selector should now show your iPhone

### Step 2: Enable Developer Mode (iOS 16+)

On your iPhone:
1. Open **Settings → Privacy & Security**
2. Scroll down to **"Developer Mode"**
3. Turn **ON**
4. Restart your iPhone when prompted

### Step 3: Sign the App (if needed)

If you see a signing error:
1. In Xcode, click project name (blue icon) in navigator
2. Select **"RAG Mobile"** target
3. Go to **"Signing & Capabilities"** tab
4. Check **"Automatically manage signing"**
5. Select your **Team** (your Apple ID)

### Step 4: Update Configuration for Device

1. Make sure you updated `Configuration.swift` with your Mac's IP address (see Part 5)
2. Make sure iPhone and Mac are on the **same WiFi network**

### Step 5: Build and Run

1. Select your iPhone from device selector
2. Click **▶ Play button**

Xcode will:
- Build the app
- Install on your iPhone
- Launch the app

### Step 6: Trust Developer (first time only)

On iPhone:
1. If app doesn't launch, go to **Settings → General → VPN & Device Management**
2. Tap your Apple ID under "Developer App"
3. Tap **"Trust [Your Name]"**
4. Go back to home screen and launch "RAG Mobile"

### Troubleshooting Physical Device

If you see "Connection Error":
- ✅ Are iPhone and Mac on same WiFi?
- ✅ Is Rails server running?
- ✅ Did you update Configuration.swift with Mac's IP?
- ✅ Try accessing `http://YOUR_MAC_IP:3000` in iPhone's Safari first

## What You've Built

🎉 **Congratulations!** You now have:

- ✅ Native iOS app wrapping your Rails dashboard
- ✅ Native navigation (back button, gestures)
- ✅ Session authentication working
- ✅ All your existing features accessible
- ✅ Works on both simulator and real iPhone

## Next Steps (Optional)

### Add App Icon

1. In Xcode, open **Assets.xcassets**
2. Click **AppIcon**
3. Drag images into the slots (need various sizes)
4. Or use a tool like: https://appicon.co/

### Customize Appearance

In `SceneDelegate.swift`, add after creating navigation controller:
```swift
// Customize navigation bar appearance
let appearance = UINavigationBarAppearance()
appearance.backgroundColor = UIColor(red: 0.31, green: 0.31, blue: 0.82, alpha: 1.0) // Indigo
appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
navigationController.navigationBar.standardAppearance = appearance
navigationController.navigationBar.scrollEdgeAppearance = appearance
navigationController.navigationBar.tintColor = .white
```

### Add Launch Screen

1. In Xcode, click **LaunchScreen.storyboard**
2. Add your app name or logo

## Helpful Xcode Shortcuts

- **Cmd + R** - Run app
- **Cmd + .** - Stop app
- **Cmd + Shift + K** - Clean build
- **Cmd + B** - Build without running
- **Cmd + /** - Comment/uncomment code
- **Cmd + [** - Shift code left
- **Cmd + ]** - Shift code right

## Need Help?

- **Console not showing?** - Click **Debug Area** button (bottom right, looks like ▭)
- **Build errors?** - Try **Product → Clean Build Folder** (Cmd+Shift+K)
- **Simulator slow?** - Try a newer model (iPhone 15 vs iPhone 11)
- **Can't find file?** - Check it's in the project navigator (left sidebar)

Enjoy your native iOS app! 🚀
