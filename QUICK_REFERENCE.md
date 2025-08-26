# Never Forget - Quick Reference Guide

## 🚀 **Core Features Overview**

### **Enhanced Todo Management**
- **4-Level Priority System**: None (white) → Low (green) → Medium (yellow) → Urgent (red)
- **Smart Categories**: Default (Personal, Work, Family) + User-defined custom categories
- **Flexible Scheduling**: Optional due dates with custom calendar picker and time wheel
- **Rich Metadata**: Description, priority, category, due date, and custom fields

### **Advanced Data Input Screen**
- **Modern Form Design**: Sections-based layout (Todo Details, Date & Time, Priority & Category, Recurring)
- **Custom Calendar Picker**: Monthly calendar view with navigation
- **Enhanced Time Selection**: Dedicated time picker wheel interface
- **Visual Priority Selection**: Color-coded priority buttons with visual feedback
- **Category Creation**: User can create custom categories with icons and colors

### **Google Calendar Integration**
- **Seamless Event Import**: Convert calendar events to todos with one tap
- **Multi-Calendar Support**: Access to all user's Google calendars
- **Event Conversion**: Intelligent mapping of calendar events to todo properties
- **Real-time Sync**: Live calendar data integration

### **Persistent Alarm System**
- **Background Processing**: Alarms continue working when app is closed
- **Flexible Scheduling**: Support for recurring and one-time alarms
- **User Notifications**: Rich notification system with custom sounds
- **Alarm Management**: Create, edit, and delete persistent alarms

## 🔧 **Technical Architecture**

### **Core Technologies**
- **SwiftUI**: Modern declarative UI framework for iOS
- **MVVM Architecture**: Clean separation of concerns with ObservableObject pattern
- **Core Data**: Persistent storage for todos and alarms
- **Google Calendar API**: Integration for event management
- **iOS 17+**: Leverages latest iOS features and APIs

### **Data Models**
```swift
// Enhanced Priority System
enum Priority: CaseIterable, Codable {
    case none, low, medium, urgent
    
    var displayName: String { ... }
    var icon: String { ... }
    var color: Color { ... }
}

// Hybrid Category System
enum Category: Codable {
    case personal, work, family
    case custom(CustomCategory)
    
    var displayName: String { ... }
    var icon: String { ... }
    var color: Color { ... }
    var isDefault: Bool { ... }
}

// Custom Category Support
struct CustomCategory: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var color: Color
}
```

### **Key UI Components**
- **CalendarDatePickerView**: Custom monthly calendar picker
- **TimePickerView**: Dedicated time selection component
- **CreateCustomCategoryView**: Category creation interface
- **UnifiedCalendarEventBlock**: Consistent event display

## 📱 **User Interface Guide**

### **Main Navigation**
- **Dashboard Tab**: Todo list and management
- **Calendar Tab**: Multiple calendar views and event integration
- **Settings Tab**: App configuration and preferences

### **Calendar Views**
- **Today View**: Hour-by-hour time slots with events and todos
- **3-Day View**: Compact view for short-term planning
- **7-Day View**: Detailed view for weekly planning
- **Monthly View**: Interactive calendar with event overlay

### **Todo Creation Flow**
1. **Tap + Button** on Dashboard or Calendar
2. **Enter Todo Name** in title field
3. **Set Due Date** using custom calendar picker (optional)
4. **Select Time** using time picker wheel (if due date set)
5. **Choose Priority** from 4-level color-coded system
6. **Select Category** from defaults or create custom
7. **Add Description** (optional)
8. **Save Todo** to create and schedule

### **Category Management**
- **Default Categories**: Personal, Work, Family (non-deletable)
- **Custom Categories**: User-created with icons and colors
- **Category Creation**: Tap "Create New Category" button
- **Category Editing**: Long press on custom categories

## 🎨 **Design System**

### **Color Palette**
- **Priority Colors**: 
  - None: White (#FFFFFF)
  - Low: Green (#34C759)
  - Medium: Yellow (#FFD60A)
  - Urgent: Red (#FF3B30)
- **Category Colors**: Dynamic based on user selection
- **System Colors**: iOS native color system integration

### **Typography**
- **Headlines**: SF Pro Display, Large Title
- **Body Text**: SF Pro Text, Body
- **Captions**: SF Pro Text, Caption
- **Labels**: SF Pro Text, Footnote

### **Layout Principles**
- **Sections**: Logical grouping of related fields
- **Spacing**: Consistent 8pt grid system
- **Padding**: 16pt standard margins
- **Corner Radius**: 8pt for cards, 16pt for buttons

## 🔒 **Security & Privacy**

### **Data Protection**
- **Local Storage**: All data stored locally on device
- **No Analytics**: No user data collection or tracking
- **Secure API**: OAuth 2.0 for Google Calendar integration
- **Token Management**: Secure storage and refresh of access tokens

### **Permissions Required**
- **Calendar Access**: Read calendar events and create todos
- **Notifications**: Local alarm notifications
- **Network**: Google Calendar API access

## 🧪 **Testing & Quality**

### **Testing Checklist**
- [ ] Todo creation with all priority levels
- [ ] Custom category creation and management
- [ ] Date and time selection accuracy
- [ ] Google Calendar event conversion
- [ ] Alarm system functionality
- [ ] Calendar view consistency
- [ ] Form validation and error handling

### **Performance Metrics**
- **App Launch**: <2 seconds
- **Todo Creation**: <1 second
- **Calendar Navigation**: <500ms
- **Event Import**: <2 seconds
- **Memory Usage**: <100MB typical

## 🚧 **Development Status**

### **✅ Completed Features**
- Enhanced todo creation system
- 4-level priority system
- Custom category management
- Advanced date and time selection
- Google Calendar integration
- Modern UI design and components

### **🔄 In Progress**
- Persistent alarm system integration
- Advanced notification management
- Performance optimization

### **📋 Planned Features**
- Recurring todo support
- Advanced filtering and search
- Data backup and sync
- Widget support
- Apple Watch companion app

## 📚 **Documentation & Support**

### **Key Documentation Files**
- **PROJECT_DOCUMENTATION.md**: Comprehensive project overview
- **DEVELOPMENT_SESSIONS.md**: Development progress tracking
- **SAFEGUARD_PROTOCOLS.md**: File protection and change protocols
- **QUICK_REFERENCE.md**: This quick reference guide

### **Development Workflow**
1. **Feature Planning**: Define requirements and scope
2. **Implementation**: Develop with MVVM architecture
3. **Testing**: Comprehensive testing and validation
4. **Documentation**: Update all documentation files
5. **Git Management**: Commit and push changes
6. **Protection**: Ensure all files are properly protected

### **File Protection Rules**
- **Source Code**: All `.swift` files protected
- **Project Files**: All `.xcodeproj` files protected
- **Configuration**: All `.plist` files protected
- **Documentation**: Only `.md` files can be updated
- **Authorization**: All changes require explicit user approval

## 🌟 **Best Practices**

### **Code Quality**
- **MVVM Pattern**: Maintain clean separation of concerns
- **SwiftUI Best Practices**: Follow Apple's guidelines
- **Error Handling**: Comprehensive error handling with user feedback
- **Performance**: Optimize for smooth animations and responsiveness

### **User Experience**
- **Accessibility**: Full VoiceOver and accessibility support
- **Dark Mode**: Full system theme integration
- **Responsive Design**: Adaptive layout for all device sizes
- **Intuitive Navigation**: Clear and consistent user flow

### **Data Management**
- **State Management**: Proper use of @State, @Binding, @ObservedObject
- **Memory Management**: Efficient cleanup of observers and timers
- **Persistence**: Reliable data storage and retrieval
- **Sync**: Seamless integration with external services

---

*Last Updated: December 24, 2024*
*Version: 2.0 - Enhanced Data Input System*
*Status: Active Development*
