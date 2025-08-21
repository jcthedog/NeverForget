# Never Forget - Todo Calendar App

A modern, intuitive iOS app built with SwiftUI that helps you manage tasks, set reminders, and never forget important things again.

## Features

### 🎯 **Task Management**
- Create, edit, and delete tasks
- Set due dates and priorities (Low, Medium, High)
- Add descriptions and tags
- Mark tasks as complete
- Visual priority indicators

### 📅 **Calendar Integration**
- View tasks by date
- Calendar picker for easy navigation
- Today's tasks overview
- Upcoming tasks list

### ⏰ **Smart Reminders**
- Set custom alarms and notifications
- Repeat options (None, Daily, Weekly, Monthly, Yearly)
- Push notifications support
- Easy enable/disable toggle

### 🎨 **Modern UI/UX**
- Clean, intuitive interface
- Custom tab navigation
- Floating action button
- Beautiful animations and transitions
- Dark mode support

## Architecture

The app follows the **MVVM (Model-View-ViewModel)** architecture pattern:

- **Models**: `Todo` and `PersistentAlarm` data structures
- **Views**: SwiftUI views for the user interface
- **ViewModels**: Business logic and data management
- **App**: Main app entry point and configuration

## Project Structure

```
TodoCalendarApp/
├── Models/
│   ├── Todo.swift
│   └── PersistentAlarm.swift
├── Views/
│   ├── DashboardView.swift
│   ├── TodoRowView.swift
│   ├── AlarmRowView.swift
│   ├── AddTodoView.swift
│   ├── EditTodoView.swift
│   ├── AddAlarmView.swift
│   └── EditAlarmView.swift
├── ViewModels/
│   └── DashboardViewModel.swift
├── Assets.xcassets/
├── Info.plist
├── ContentView.swift
└── NeverForgetApp.swift
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd TodoCalendarApp
   ```

2. **Open in Xcode**
   - Open `TodoCalendarApp.xcodeproj` in Xcode
   - Select your target device or simulator
   - Build and run the project

3. **First Run**
   - Grant notification permissions when prompted
   - Start creating your first task or reminder

## Usage

### Creating Tasks
1. Tap the floating action button (+)
2. Select "Add Task"
3. Fill in the task details
4. Set due date and priority
5. Add optional tags
6. Tap "Add" to save

### Setting Reminders
1. Tap the floating action button (+)
2. Select "Add Reminder"
3. Enter reminder title and message
4. Choose date and time
5. Set repeat frequency
6. Tap "Add" to save

### Managing Tasks
- Tap the checkbox to mark as complete
- Swipe or use the menu to edit/delete
- View tasks by date in the calendar tab
- Filter by priority and completion status

## Development

### Adding New Features
- Follow the existing MVVM pattern
- Create new views in the `Views/` directory
- Add business logic to appropriate ViewModels
- Update models as needed

### Data Persistence
Currently using in-memory storage. To implement persistence:
- Add Core Data models
- Update ViewModels to use Core Data
- Implement data migration if needed

### Testing
- Add unit tests for ViewModels
- Create UI tests for critical user flows
- Test notification functionality on device

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or issues:
- Create an issue in the repository
- Contact the development team
- Check the documentation

---

**Never Forget** - Because life is too important to forget the little things. ✨
