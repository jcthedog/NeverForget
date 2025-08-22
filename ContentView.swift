import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            TodoListView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Todos")
                }
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            AlarmCenterView()
                .tabItem {
                    Image(systemName: "alarm.fill")
                    Text("Alarms")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.purple)
    }
}

// MARK: - Placeholder Views
struct TodoListView: View {
    var body: some View {
        NavigationView {
            Text("Todo List View")
                .navigationTitle("Todos")
        }
    }
}

struct AlarmCenterView: View {
    var body: some View {
        NavigationView {
            Text("Alarm Center View")
                .navigationTitle("Alarms")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Text("Settings View")
                .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
}
