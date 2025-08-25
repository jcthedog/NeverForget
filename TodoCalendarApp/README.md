# 📱 Never Forget - Persistent Alarm App

A modern iOS app that combines powerful todo management with integrated calendar functionality and a unique persistent alarm system designed for busy people who can't immediately act on notifications.

## ✨ Key Features

### 🔔 Persistent Alarm System
- **Non-dismissible reminders** that keep going until manually acknowledged
- **Escalating urgency** with multiple notification levels
- **Smart snoozing** with contextual options
- **Fallback mechanisms** ensuring you never miss important tasks

### 📋 Todo Management
- Quick add with natural language parsing
- Smart categories and priority levels
- Subtasks and progress tracking
- Recurring task patterns

### 📅 Calendar Integration
- Unified view of todos and calendar events
- Drag & drop scheduling
- Time blocking functionality
- Conflict detection

## 🏗️ Project Structure

```
NeverForget/
├── Models/
│   ├── Todo.swift              # Core todo data model
│   └── PersistentAlarm.swift   # Alarm escalation system
├── ViewModels/
│   └── DashboardViewModel.swift # Main dashboard logic
├── Views/
│   ├── DashboardView.swift     # Main dashboard UI
│   └── ContentView.swift       # Tab-based navigation
├── NeverForgetApp.swift        # App entry point
└── README.md                   # This file
```

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Setup Instructions
1. Create a new Xcode project
2. Copy the source files to your project
3. Build and run on simulator or device

### Project Configuration
- Set deployment target to iOS 17.0+
- Enable CloudKit capabilities (for future sync)
- Configure notification permissions

## 🎯 Core Components

### Dashboard View
The main screen showing:
- **Active Alarms**: Currently escalating reminders
- **Quick Actions**: Add todo, view calendar, search
- **Today's Focus**: Progress tracking and upcoming tasks

### Alarm Escalation System
Five levels of increasing urgency:
1. **Gentle** (🟢): Standard notification
2. **Persistent** (🟡): Repeats every 5 minutes
3. **Urgent** (🟠): Repeats every 2 minutes + sound
4. **Critical** (🔴): Repeats every minute + sound + vibration
5. **Emergency** (🟣): Full screen alert + sound + vibration

### Smart Snooze Options
- Quick presets: 5 min, 15 min, 1 hour, 3 hours
- Location-based: "Remind me when I arrive at work"
- App-based: "Remind me when I open email"
- Custom timing: "Remind me tomorrow morning"

## 🔧 Technical Implementation

### Data Models
- **Todo**: Core task structure with priority, category, and alarm settings
- **PersistentAlarm**: Manages escalation state and notification timing
- **EscalationLevel**: Defines notification behavior and timing

### Architecture
- **MVVM**: Clean separation of concerns
- **Combine**: Reactive data binding
- **SwiftUI**: Modern declarative UI framework
- **CloudKit**: iCloud sync (planned)

### Key Services
- **NotificationService**: Handles local and push notifications
- **AlarmService**: Manages escalation logic and timing
- **TodoService**: CRUD operations for tasks
- **CalendarService**: EventKit integration

## 🎨 UI/UX Design

### Design Principles
- **Alarm-Centric**: Persistent alarms are always visible
- **Progressive Disclosure**: Simple interface that reveals complexity
- **Visual Hierarchy**: Clear priority and escalation states
- **Gesture-First**: Intuitive swipes and taps

### Color Scheme
- **Priority Colors**: Green (Low), Yellow (Medium), Red (High)
- **Escalation Colors**: Green → Yellow → Orange → Red → Purple
- **Accent Color**: Purple for primary actions

## 📱 User Experience Flow

### Scenario: "Call client at 2pm"
1. **2:00 PM**: Gentle notification appears
2. **2:05 PM**: Escalates to persistent (every 5 min)
3. **2:15 PM**: Escalates to urgent (every 2 min + sound)
4. **2:30 PM**: Escalates to critical (every 1 min + sound + vibration)
5. **3:00 PM**: Emergency mode - full screen alert

### Acknowledgment Options
- **Complete**: Mark task as done
- **Snooze**: Choose when to remind again
- **Reschedule**: Move to different date/time
- **Delegate**: Assign to someone else

## 🔮 Future Enhancements

### Phase 2 Features
- Location-based escalation triggers
- App-based escalation triggers
- Custom alarm sounds and patterns
- Escalation analytics and insights

### Phase 3 Features
- Apple Watch companion app
- Widgets for home screen
- Focus mode integration
- Advanced recurring patterns

## 🧪 Testing

### Unit Tests
- Alarm escalation logic
- Todo CRUD operations
- Date calculations and formatting

### UI Tests
- Dashboard interactions
- Alarm acknowledgment flow
- Todo completion workflow

### Manual Testing
- Notification permissions
- Background app refresh
- Different device orientations

## 📋 Development Checklist

### MVP Features
- [x] Core data models
- [x] Dashboard UI
- [x] Basic alarm system
- [x] Todo management
- [ ] Calendar integration
- [ ] Notification service
- [ ] Local persistence

### Post-MVP
- [ ] CloudKit sync
- [ ] Advanced escalation
- [ ] Custom sounds
- [ ] Analytics dashboard
- [ ] Settings configuration

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

## 📄 License

Personal use only.

---

**Built with ❤️ using SwiftUI and Combine**
