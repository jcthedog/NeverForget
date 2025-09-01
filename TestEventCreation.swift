import SwiftUI

// MARK: - Minimal Event Creation Test
struct TestEventCreation: View {
    @State private var showingSheet = false
    
    var body: some View {
        VStack {
            Text("Test Event Creation")
                .font(.title)
            
            Button("Test Create Event") {
                print("🔍 Test button tapped")
                showingSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showingSheet) {
            MinimalEventForm()
        }
    }
}

struct MinimalEventForm: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Minimal Event Form")
                    .font(.title2)
                
                TextField("Event Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .padding(.horizontal)
                
                Button("Create") {
                    print("✅ Creating event: \(title)")
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Test Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TestEventCreation()
}




