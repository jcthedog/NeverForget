# Never Forget - Project Documentation

## Project Overview
**Never Forget** is a SwiftUI iOS application that serves as an intelligent todo companion, helping users stay organized and never forget what matters most. The app integrates todo management, calendar functionality, and alarm systems with Google Calendar synchronization.

## Current Status
- **Last Updated**: [DATE_PLACEHOLDER]
- **Current Version**: 1.0.0
- **Development Phase**: Active Development
- **Last Chat Session**: [SESSION_PLACEHOLDER]

## Core Features

### 1. Todo Management
- **CRUD Operations**: Create, read, update, delete todos
- **Priority System**: Low, Medium, High priority levels
- **Categories**: Personal, Work, Shopping, Health, etc.
- **Due Dates**: Optional due dates with smart formatting
- **Recurring Patterns**: Daily, weekly, monthly, yearly recurring todos
- **Subtasks**: Support for breaking down complex todos
- **Search & Filter**: Advanced filtering by status, date, priority, category

### 2. Calendar Integration
- **Google Calendar Sync**: Full integration with Google Calendar API
- **Event Import**: Convert calendar events to todos
- **Calendar View**: Monthly calendar with todo overlay
- **Event Management**: View, edit, and manage calendar events

### 3. Alarm System
- **Persistent Alarms**: Reliable alarm notifications
- **Custom Schedules**: Daily, weekly, or custom repeat patterns
- **Notification Types**: Standard, gentle, urgent notification styles
- **Snooze Functionality**: Multiple snooze duration options

### 4. Dashboard
- **Overview Statistics**: Todo counts, upcoming deadlines, active alarms
- **Quick Actions**: Add todos, set alarms, view calendar
- **Smart Suggestions**: AI-powered todo recommendations

## Technical Architecture

### File Structure
```
Never Forget/
├── Core Views/
│   ├── ContentView.swift (Main tab navigation)
│   ├── DashboardView.swift (Main dashboard)
│   ├── CalendarView.swift (Calendar functionality)
│   └── EventImportView.swift (Event import)
├── View Models/
│   └── DashboardViewModel.swift (Main business logic)
├── Models/
│   ├── Todo.swift (Todo data model)
│   ├── PersistentAlarm.swift (Alarm data model)
│   ├── GoogleCalendarEvent.swift (Calendar event model)
│   └── SharedTypes.swift (Shared enums and types)
├── Services/
│   ├── GoogleCalendarService.swift (Google Calendar API)
│   └── GoogleCalendarConfig.swift (API configuration)
├── Supporting Views/
│   └── GoogleCalendarSelectionView.swift (Calendar selection)
└── App/
    └── Never_ForgetApp.swift (App entry point)
```

### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data binding
- **Core Data**: Local data persistence (planned)
- **Google Calendar API**: Calendar synchronization
- **UserNotifications**: Local notification system

### Data Models

#### Todo Model
```swift
struct Todo: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var category: Category
    var subtasks: [Subtask]
    var recurringPattern: RecurringPattern?
    var alarmSettings: AlarmSettings?
    var createdAt: Date
    var modifiedAt: Date
}
```

#### Alarm Model
```swift
struct PersistentAlarm: Identifiable, Codable {
    let id: UUID
    var title: String
    var message: String
    var time: Date
    var notificationType: NotificationType
    var repeatDays: Set<Int>
    var isEnabled: Bool
}
```

## Development Guidelines

### Code Standards
- **SwiftUI Best Practices**: Follow Apple's SwiftUI guidelines
- **MVVM Architecture**: Separate view logic from business logic
- **Error Handling**: Comprehensive error handling with user feedback
- **Accessibility**: Full VoiceOver and accessibility support
- **Performance**: Optimize for smooth animations and responsiveness

### Testing Strategy
- **Unit Tests**: Test view models and business logic
- **UI Tests**: Test user interactions and workflows
- **Integration Tests**: Test Google Calendar API integration

### Git Workflow
- **Feature Branches**: Create separate branches for new features
- **Pull Requests**: Code review before merging
- **Commit Messages**: Clear, descriptive commit messages
- **Tagging**: Tag releases with version numbers

## Known Issues & Technical Debt

### Current Issues
- [ ] None currently identified

### Technical Debt
- [ ] Implement Core Data for persistent storage
- [ ] Add comprehensive error handling
- [ ] Implement offline mode
- [ ] Add unit tests for view models
- [ ] Optimize calendar view performance

### Planned Improvements
- [ ] Dark mode support
- [ ] Widget support
- [ ] Apple Watch companion app
- [ ] Siri integration
- [ ] Advanced recurring patterns
- [ ] Todo templates

## Recent Changes

### [DATE_PLACEHOLDER] - [SESSION_PLACEHOLDER]
- **Changes Made**: [DESCRIBE_CHANGES]
- **Files Modified**: [LIST_FILES]
- **Issues Resolved**: [LIST_ISSUES]
- **New Features**: [LIST_FEATURES]

## Next Steps

### Immediate Priorities
1. [ ] [TASK_1]
2. [ ] [TASK_2]
3. [ ] [TASK_3]

### Short-term Goals (1-2 weeks)
1. [ ] [GOAL_1]
2. [ ] [GOAL_2]

### Long-term Vision (1-2 months)
1. [ ] [VISION_1]
2. [ ] [VISION_2]

## Resources & References

### Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Google Calendar API](https://developers.google.com/calendar)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### Development Tools
- **Xcode**: Primary development environment
- **Git**: Version control
- **GitHub**: Code repository and collaboration

## Contact & Support

- **Developer**: [YOUR_NAME]
- **Project Repository**: [GITHUB_URL]
- **Support Email**: [EMAIL]

---

*This document is automatically updated at the end of each development session. Please keep it current and comprehensive.*
