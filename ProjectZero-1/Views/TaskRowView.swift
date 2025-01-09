import SwiftUI

struct TaskRowView: View {
    let task: Task
    let onToggle: () -> Void
    let onEdit: (String) -> Void
    let onDelete: () -> Void
    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    
    var body: some View {
        ZStack {
            // Delete button background
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring()) {
                        offset = 0
                        onDelete()
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 90, height: 50)
                }
                .background(Color.red)
                .cornerRadius(15)
                .padding(.trailing, 16)
            }
            .opacity(offset < 0 ? 1 : 0)
            
            // Main content
            HStack(spacing: 16) {
                // Category Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: task.category.gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: task.category.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if isEditing {
                        TextField("Görev başlığı", text: $editedTitle, onCommit: {
                            isEditing = false
                            if !editedTitle.isEmpty {
                                onEdit(editedTitle)
                            }
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(task.title)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(task.isCompleted ? .gray : .primary)
                            .font(.system(size: 17, weight: .medium))
                        
                        Text(task.category.rawValue)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(task.category.gradient[0])
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if !isEditing {
                    Button(action: onToggle) {
                        ZStack {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: task.category.gradient),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: 28, height: 28)
                            
                            if task.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(task.category.gradient[0])
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation {
                            offset = min(0, value.translation.width)
                            isSwiped = offset < 0
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if value.translation.width < -50 {
                                offset = -90
                            } else {
                                offset = 0
                                isSwiped = false
                            }
                        }
                    }
            )
            .onChange(of: task.category) { _ in
                withAnimation(.spring()) {
                    offset = 0
                    isSwiped = false
                }
            }
            .contextMenu {
                Button(action: {
                    editedTitle = task.title
                    isEditing.toggle()
                }) {
                    Label("Düzenle", systemImage: "pencil")
                }
                
                Button(action: onToggle) {
                    Label(
                        task.isCompleted ? "Tamamlanmadı İşaretle" : "Tamamlandı İşaretle",
                        systemImage: task.isCompleted ? "circle" : "checkmark.circle"
                    )
                }
                
                Button(role: .destructive, action: onDelete) {
                    Label("Sil", systemImage: "trash")
                }
            }
        }
    }
} 


