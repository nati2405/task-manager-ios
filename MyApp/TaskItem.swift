import Foundation

// One task, matching the MongoDB document sent by the server.
// (Named TaskItem because "Task" is already a built-in Swift name.)
struct TaskItem: Codable, Identifiable {
    let id: String    // MongoDB's _id
    var text: String  // the task description
    var done: Bool    // completion status

    // Map MongoDB's "_id" field to Swift's "id"
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case text, done
    }
}
