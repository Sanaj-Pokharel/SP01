# SP01 Widget Setup Instructions

## What's Ready
✅ Widget code is created in `SP01Widget/` folder  
✅ Main app analyzes next 12 hours of weather  
✅ Main app saves suggestions for the widget  
✅ Widget updates at 7 AM every morning  

## What You Need to Do in Xcode

### Step 1: Add Widget Extension Target
1. Open `SP01.xcodeproj` in Xcode
2. Go to **File** → **New** → **Target...**
3. In the template chooser:
   - Select **iOS** at the top
   - Choose **Widget Extension**
   - Click **Next**
4. Configure the widget:
   - **Product Name**: `SP01Widget`
   - **Include Configuration Intent**: **Uncheck** this box
   - Click **Finish**
5. When asked "Activate 'SP01Widget' scheme?", click **Activate**

### Step 2: Replace Generated Widget Code
1. In Xcode's Project Navigator (left sidebar), find the **SP01Widget** folder
2. Delete the generated `SP01Widget.swift` file (move to trash)
3. Drag the `SP01Widget/SP01Widget.swift` file from Finder into the **SP01Widget** folder in Xcode
4. When asked, make sure **SP01Widget** target is checked, then click **Finish**

### Step 3: Set Up App Groups (Required for Data Sharing)

#### For the Main App:
1. In Xcode, select the **SP01** project (blue icon at the top of the navigator)
2. Select the **SP01** target (under TARGETS)
3. Go to the **Signing & Capabilities** tab
4. Click **+ Capability** button
5. Search for and add **App Groups**
6. Under App Groups, click **+** and add: `group.com.sanaj.SP01`
7. Make sure the checkbox next to it is checked

#### For the Widget:
1. Still in the project settings, select the **SP01Widget** target (under TARGETS)
2. Go to the **Signing & Capabilities** tab
3. Click **+ Capability** button
4. Search for and add **App Groups**
5. Under App Groups, click **+** and add: `group.com.sanaj.SP01` (same as above)
6. Make sure the checkbox next to it is checked

### Step 4: Share Weather Models with Widget
1. In the Project Navigator, find **SP01/Models/Weather.swift**
2. Click on the file to select it
3. In the **File Inspector** (right sidebar), under **Target Membership**:
   - Make sure **SP01** is checked ✅
   - Also check **SP01Widget** ✅

Do the same for:
- **SP01/Services/SharedDataManager.swift** (check both SP01 and SP01Widget)

### Step 5: Build and Run
1. Select **SP01** scheme (top-left, next to the play button)
2. Build and run on your device (⌘R)
3. Open the app, allow location, and load weather
4. Go to your home screen
5. Long-press on the home screen → tap **+** (top-left)
6. Search for **SP01**
7. Choose the widget size (Small or Medium)
8. Tap **Add Widget**

The widget will show "What to bring" based on the next 12 hours of weather and will update at 7 AM every morning.

## Troubleshooting

**Widget shows "Looking good" even when weather suggests otherwise:**
- Make sure App Groups are set up correctly for both targets
- Make sure Weather.swift and SharedDataManager.swift have both targets checked
- Rebuild the app and widget

**Widget doesn't update at 7 AM:**
- Widgets update on iOS's schedule, not exactly at 7 AM
- iOS may delay updates to save battery
- Opening the main app will force a widget refresh

**Build errors:**
- Make sure you added the Widget Extension target first
- Make sure all files have the correct target membership
- Clean build folder (⌘⇧K) and rebuild
