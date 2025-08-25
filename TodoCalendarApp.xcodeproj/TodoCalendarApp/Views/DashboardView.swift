import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTab = 0
    @State private var showingGoogleCalendar = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    todosTab
                        .tag(0)
                    
                    calendarTab
                        .tag(1)
                    
                    alarmsTab
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Custom Tab Bar
                customTabBar
                
                // Floating Action Button
                floatingActionButton
                
                // Google Calendar Integration Button
                googleCalendarButton
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showingAddTodo) {
            AddTodoView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingAddAlarm) {
            AddAlarmView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingGoogleCalendar) {
            GoogleCalendarSelectionView()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Never Forget")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Your personal task manager")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.showingAddTodo = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            
            // Quick Stats
            HStack(spacing: 20) {
                StatCard(title: "Pending", value: "\(viewModel.pendingTodos.count)", color: .orange)
                StatCard(title: "Completed", value: "\(viewModel.completedTodos.count)", color: .green)
                StatCard(title: "Active Alarms", value: "\(viewModel.activeAlarms.count)", color: .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Todos Tab
    
    private var todosTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.todos.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.todos) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Calendar Tab
    
    private var calendarTab: some View {
        VStack {
            DatePicker(
                "Select Date",
                selection: $viewModel.selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .padding()
            
            if !viewModel.todayTodos.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Tasks")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.todayTodos) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Alarms Tab
    
    private var alarmsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.alarms.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Alarms Set")
                            .font(.headline)
                        
                        Text("Tap the + button to create your first reminder")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 50)
                } else {
                    ForEach(viewModel.alarms) { alarm in
                        AlarmRowView(alarm: alarm, viewModel: viewModel)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "Tasks",
                icon: "checklist",
                isSelected: selectedTab == 0
            ) {
                withAnimation { selectedTab = 0 }
            }
            
            TabButton(
                title: "Calendar",
                icon: "calendar",
                isSelected: selectedTab == 1
            ) {
                withAnimation { selectedTab = 1 }
            }
            
            TabButton(
                title: "Alarms",
                icon: "bell",
                isSelected: selectedTab == 2
            ) {
                withAnimation { selectedTab = 2 }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
    
    // MARK: - Google Calendar Button
    
    private var googleCalendarButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: {
                    showingGoogleCalendar = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title3)
                        Text("Import Calendar")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 180) // Above floating action button
            }
        }
    }
    
    // MARK: - Floating Action Button
    
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Menu {
                    Button(action: {
                        viewModel.showingAddTodo = true
                    }) {
                        Label("Add Task", systemImage: "checkmark.circle")
                    }
                    
                    Button(action: {
                        viewModel.showingAddAlarm = true
                    }) {
                        Label("Add Reminder", systemImage: "bell")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100) // Above tab bar
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Tasks Yet")
                .font(.headline)
            
            Text("Create your first task to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 50)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .blue : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    DashboardView()
}
