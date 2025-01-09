import Foundation
import SwiftUI
import UserNotifications

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var selectedCategory: TaskCategory?
    @Published var sortOption: SortOption = .date
    private let tasksKey = "tasks"
    
    enum SortOption {
        case date
        case priority
        case dueDate
        case category
    }
    
    var filteredTasks: [Task] {
        var filtered = tasks
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply sorting
        switch sortOption {
        case .date:
            filtered.sort { $0.timestamp > $1.timestamp }
        case .priority:
            filtered.sort { $0.priority.rawValue > $1.priority.rawValue }
        case .dueDate:
            filtered.sort { 
                guard let date1 = $0.dueDate else { return false }
                guard let date2 = $1.dueDate else { return true }
                return date1 < date2
            }
        case .category:
            filtered.sort { $0.category.rawValue < $1.category.rawValue }
        }
        
        return filtered
    }
    
    init() {
        loadTasks()
        requestNotificationPermission()
    }
    
    // MARK: - CRUD Operations
    
    func addTask(
        title: String,
        category: TaskCategory,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        notes: String? = nil,
        reminderEnabled: Bool = false
    ) {
        let task = Task(
            title: title,
            category: category,
            priority: priority,
            dueDate: dueDate,
            notes: notes,
            reminderEnabled: reminderEnabled
        )
        tasks.append(task)
        saveTasks()
        
        if reminderEnabled, let dueDate = dueDate {
            scheduleNotification(for: task, at: dueDate)
        }
    }
    
    func deleteTask(at indexSet: IndexSet) {
        let tasksToDelete = indexSet.map { filteredTasks[$0] }
        tasks.removeAll { task in
            tasksToDelete.contains { $0.id == task.id }
        }
        
        // Remove notifications for deleted tasks
        for task in tasksToDelete {
            cancelNotification(for: task)
        }
        
        saveTasks()
    }
    
    func moveTask(from: IndexSet, to: Int) {
        var movedTasks = filteredTasks
        movedTasks.move(fromOffsets: from, toOffset: to)
        
        // Update the main tasks array while preserving categories
        for (index, task) in movedTasks.enumerated() {
            if let mainIndex = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[mainIndex] = task
            }
        }
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            
            // If task is completed, remove its notification
            if tasks[index].isCompleted {
                cancelNotification(for: task)
            }
            
            saveTasks()
        }
    }
    
    func updateTask(_ task: Task, with title: String) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].title = title
            saveTasks()
        }
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleNotification(for task: Task, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Görev Hatırlatıcı"
        content.body = task.title
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotification(for task: Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
    
    // MARK: - Persistence
    
    private func saveTasks() {
        if let encodedData = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encodedData, forKey: tasksKey)
        }
    }
    
    private func loadTasks() {
        guard let data = UserDefaults.standard.data(forKey: tasksKey),
              let savedTasks = try? JSONDecoder().decode([Task].self, from: data) else { return }
        self.tasks = savedTasks
    }
} 