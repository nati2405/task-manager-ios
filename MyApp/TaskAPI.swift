import Foundation

// Handles all network calls to the Express server hosted on Render
struct TaskAPI {
    // Online server URL, so the app works on any network (not just near my laptop)
    static let baseURL = URL(string: "https://task-server-2o1z.onrender.com/api/tasks")!

    // READ: GET all tasks from MongoDB
    static func fetchTasks() async throws -> [TaskItem] {
        let (data, _) = try await URLSession.shared.data(from: baseURL)
        return try JSONDecoder().decode([TaskItem].self, from: data)
    }

    // CREATE: POST a new task, the server returns the saved task
    static func addTask(text: String) async throws -> TaskItem {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["text": text])
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TaskItem.self, from: data)
    }

    // TOGGLE: PATCH flips the done value on the server
    static func toggleTask(id: String) async throws -> TaskItem {
        var request = URLRequest(url: baseURL.appendingPathComponent(id))
        request.httpMethod = "PATCH"
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TaskItem.self, from: data)
    }
    // EDIT: PUT the new text, the server returns the updated task
    static func editTask(id: String, text: String) async throws -> TaskItem {
        var request = URLRequest(url: baseURL.appendingPathComponent(id))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["text": text])
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TaskItem.self, from: data)
    }
    // DELETE: remove the task from MongoDB
    static func deleteTask(id: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent(id))
        request.httpMethod = "DELETE"
        _ = try await URLSession.shared.data(for: request)
    }
}
