import SwiftUI

// Background for Glass effect
struct GlassBackground: View {
    var body: some View {
        if #available(iOS 15.0, *) {
            Rectangle()
                .fill(.ultraThinMaterial)
        } else {
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .opacity(0.8)
        }
    }
}

// Content View (Ana Görünüm)
struct ContentView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var newTaskTitle = ""
    @State private var selectedCategory: TaskCategory = .personal
    @State private var isAddingTask = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: selectedCategory.gradient),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .opacity(0.3)
                
                VStack(spacing: 0) {
                    // Category Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TaskCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: viewModel.selectedCategory == category,
                                    action: {
                                        withAnimation(.spring()) {
                                            viewModel.selectedCategory = viewModel.selectedCategory == category ? nil : category
                                            if viewModel.selectedCategory == category {
                                                selectedCategory = category
                                            }
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    
                    // Task List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.filteredTasks.enumerated()), id: \.element.id) { index, task in
                                TaskRowView(
                                    task: task,
                                    onToggle: { viewModel.toggleTaskCompletion(task) },
                                    onEdit: { newTitle in
                                        viewModel.updateTask(task, with: newTitle)
                                    },
                                    onDelete: {
                                        withAnimation {
                                            viewModel.deleteTask(at: IndexSet([index]))
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Görevler")
            .navigationBarItems(
                trailing: HStack(spacing: 16) {
                    Button(action: { isDarkMode.toggle() }) {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 20))
                            .foregroundColor(selectedCategory.gradient[0])
                    }
                    
                    Button(action: { isAddingTask.toggle() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(selectedCategory.gradient[0])
                    }
                }
            )
            .sheet(isPresented: $isAddingTask) {
                AddTaskView(
                    isPresented: $isAddingTask,
                    selectedCategory: $selectedCategory,
                    onAdd: { title in
                        viewModel.addTask(title: title, category: selectedCategory)
                    }
                )
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// CategoryButton View (Kategori Seçici Buton)
struct CategoryButton: View {
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                Text(category.rawValue)
                    .font(.system(size: 15, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: category.gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        GlassBackground()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            )
            .foregroundColor(isSelected ? .white : category.gradient[0])
        }
    }
}

// Add Task View (Yeni Görev Ekleme Görünümü)
struct AddTaskView: View {
    @Binding var isPresented: Bool
    @Binding var selectedCategory: TaskCategory
    let onAdd: (String) -> Void
    @State private var taskTitle = ""
    @State private var selectedPriority: TaskPriority = .medium
    @State private var selectedDate: Date = Date()
    @State private var notes: String = ""
    @State private var isDatePickerVisible = false
    @State private var reminderEnabled = false
    @FocusState private var isTitleFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with gradient background
                        VStack(spacing: 16) {
                            // Task Input Field with custom styling
                            TextField("Görev başlığı", text: $taskTitle)
                                .font(.system(size: 18, weight: .medium))
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .focused($isTitleFocused)
                                .submitLabel(.done)
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: selectedCategory.gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .opacity(0.1)
                        )
                        
                        // Category Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Kategori")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(TaskCategory.allCases, id: \.self) { category in
                                        CategoryButton(
                                            category: category,
                                            isSelected: selectedCategory == category,
                                            action: { selectedCategory = category }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        
                        // Priority Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Öncelik")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                ForEach(TaskPriority.allCases, id: \.self) { priority in
                                    Button(action: { selectedPriority = priority }) {
                                        HStack {
                                            Circle()
                                                .fill(priority.color)
                                                .frame(width: 12, height: 12)
                                            Text(priority.title)
                                                .font(.system(size: 15, weight: .medium))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedPriority == priority ? 
                                                    priority.color.opacity(0.2) : 
                                                    Color(UIColor.secondarySystemBackground)
                                                )
                                        )
                                    }
                                    .foregroundColor(selectedPriority == priority ? 
                                        priority.color : .primary)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        
                        // Due Date Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bitiş Tarihi")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Button(action: { 
                                withAnimation {
                                    isDatePickerVisible.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text(selectedDate.formatted(date: .long, time: .shortened))
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            if isDatePickerVisible {
                                DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.graphical)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        
                        // Reminder Toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $reminderEnabled) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(selectedCategory.gradient[0])
                                    Text("Hatırlatıcı")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notlar")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                        
                        // Bottom Action Buttons
                        VStack {
                            Button(action: {
                                if !taskTitle.isEmpty {
                                    onAdd(taskTitle)
                                    isPresented = false
                                }
                            }) {
                                Text("Görevi Ekle")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: selectedCategory.gradient),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(15)
                            }
                            .disabled(taskTitle.isEmpty)
                            .opacity(taskTitle.isEmpty ? 0.6 : 1)
                            
                            Button(action: { isPresented = false }) {
                                Text("İptal")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                    }
                }
                .onAppear {
                    isTitleFocused = true
                }
            }
            .navigationBarHidden(true)
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    ContentView()
}
