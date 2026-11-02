import SwiftUI

// Colors from the Figma AI design
extension Color {
    static let accentIndigo = Color(red: 0x6C/255, green: 0x70/255, blue: 0xDB/255)
    static let accentLight = Color(red: 0xE9/255, green: 0xEA/255, blue: 0xFB/255)
    static let screenBackground = Color(red: 0xF4/255, green: 0xF5/255, blue: 0xFA/255)
    static let textDark = Color(red: 0x1C/255, green: 0x1C/255, blue: 0x28/255)
    static let textGray = Color(red: 0x9A/255, green: 0x9A/255, blue: 0xAB/255)
}

// Main screen: header, input bar, and scrollable task list
struct ContentView: View {
    @State private var tasks: [TaskItem] = []  // tasks loaded from the server
    @State private var newText = ""            // text typed in the input
    @State private var isLoading = true        // true during the first load
    @State private var errorMessage: String?   // shown in an alert if a request fails

    // Counts shown in the header and section title
    private var completedCount: Int { tasks.filter { $0.done }.count }
    private var remainingCount: Int { tasks.count - completedCount }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // HEADER: title and task count, icon box on the right
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Tasks")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.textDark)
                    Text("\(tasks.count) \(tasks.count == 1 ? "task" : "tasks") · \(remainingCount) remaining")
                        .font(.footnote)
                        .foregroundStyle(Color.textGray)
                }
                Spacer()
                Image(systemName: "checklist")
                    .font(.title3)
                    .foregroundStyle(Color.accentIndigo)
                    .frame(width: 44, height: 44)
                    .background(Color.accentLight, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.bottom, 20)

            // CREATE: rounded input and indigo Add button
            HStack(spacing: 10) {
                TextField("Add a new task...", text: $newText)
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(Color.textDark)
                    .onSubmit(addTask)
                Button(action: addTask) {
                    Text("Add")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .frame(height: 52)
                        .background(Color.accentIndigo, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.bottom, 24)

            // SECTION TITLE: "Your tasks" with the completed count
            HStack {
                Text("Your tasks")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textDark)
                Spacer()
                Text("\(completedCount) completed")
                    .font(.caption)
                    .foregroundStyle(Color.textGray)
            }
            .padding(.bottom, 8)

            // LIST: SwiftUI List only builds the rows that are on screen
            if isLoading {
                ProgressView()
                    .tint(Color.accentIndigo)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                Spacer()
            } else if tasks.isEmpty {
                Text("No tasks yet. Add one above!")
                    .foregroundStyle(Color.textGray)
                    .padding(.top, 12)
                Spacer()
            } else {
                List {
                    ForEach(tasks) { task in
                        TaskRow(task: task,
                                onToggle: { toggle(task) },
                                onDelete: { delete(task) })
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable { await loadTasks() } // pull down to reload from the server
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(Color.screenBackground.ignoresSafeArea())
        .task { await loadTasks() } // LOAD: runs when the screen first appears
        .alert("Something went wrong",
               isPresented: Binding(get: { errorMessage != nil },
                                    set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // LOAD: get all tasks from the server
    private func loadTasks() async {
        do {
            tasks = try await TaskAPI.fetchTasks()
        } catch {
            errorMessage = "Could not load tasks. Check your internet connection."
        }
        isLoading = false
    }

    // CREATE: send the new task to the server, then add the saved task to the list
    private func addTask() {
        let text = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return } // ignore empty input
        newText = ""
        Task {
            do {
                let saved = try await TaskAPI.addTask(text: text)
                tasks.append(saved)
            } catch {
                errorMessage = "Could not add task."
            }
        }
    }

    // TOGGLE: ask the server to flip done, then swap in the updated task
    private func toggle(_ task: TaskItem) {
        Task {
            do {
                let updated = try await TaskAPI.toggleTask(id: task.id)
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[index] = updated
                }
            } catch {
                errorMessage = "Could not update task."
            }
        }
    }

    // DELETE: remove the task on the server, then remove it from the list
    private func delete(_ task: TaskItem) {
        Task {
            do {
                try await TaskAPI.deleteTask(id: task.id)
                tasks.removeAll { $0.id == task.id }
            } catch {
                errorMessage = "Could not delete task."
            }
        }
    }
}

// One task card: round checkbox, task text, trash button
struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Round checkbox: empty gray circle, or filled indigo check when done
            Button(action: onToggle) {
                Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.done ? Color.accentIndigo : Color.textGray)
            }
            .buttonStyle(.borderless) // so tapping one button doesn't trigger the whole row

            // Task text: strikethrough and gray when completed
            Text(task.text)
                .strikethrough(task.done)
                .foregroundStyle(task.done ? Color.textGray : Color.textDark)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Delete button with the trash icon from the Figma design
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.textGray)
            }
            .buttonStyle(.borderless)
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

#Preview {
    ContentView()
}
