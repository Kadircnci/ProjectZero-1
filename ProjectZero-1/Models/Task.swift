import Foundation
import SwiftUI

enum TaskPriority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    
    var title: String {
        switch self {
        case .low: return "Düşük"
        case .medium: return "Orta"
        case .high: return "Yüksek"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

enum TaskCategory: String, Codable, CaseIterable {
    case home = "Ev"
    case work = "İş"
    case school = "Okul"
    case personal = "Kişisel"
    case shopping = "Alışveriş"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .school: return "book.fill"
        case .personal: return "person.fill"
        case .shopping: return "cart.fill"
        }
    }
    
    var gradient: [Color] {
        switch self {
        case .home: return [Color(hex: "4158D0"), Color(hex: "C850C0")]
        case .work: return [Color(hex: "0093E9"), Color(hex: "80D0C7")]
        case .school: return [Color(hex: "8EC5FC"), Color(hex: "E0C3FC")]
        case .personal: return [Color(hex: "FF9A8B"), Color(hex: "FF6A88")]
        case .shopping: return [Color(hex: "FBAB7E"), Color(hex: "F7CE68")]
        }
    }
}

struct Task: Identifiable, Codable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var timestamp: Date
    var category: TaskCategory
    var priority: TaskPriority
    var dueDate: Date?
    var notes: String?
    var reminderEnabled: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        timestamp: Date = Date(),
        category: TaskCategory = .personal,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        notes: String? = nil,
        reminderEnabled: Bool = false
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.timestamp = timestamp
        self.category = category
        self.priority = priority
        self.dueDate = dueDate
        self.notes = notes
        self.reminderEnabled = reminderEnabled
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 