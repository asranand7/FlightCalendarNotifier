import Foundation

struct TodoistDue: Codable {
    let date: String       // "YYYY-MM-DD" or "YYYY-MM-DDTHH:MM:SSZ"
    let timezone: String?

    // True when the due date includes a specific time
    var isDatetime: Bool { date.contains("T") }
}

struct TodoistTask: Codable {
    let id: String
    let content: String
    let description: String?
    let due: TodoistDue?

    var url: String { "https://todoist.com/app/task/\(id)" }
}

private struct TodoistTasksResponse: Codable {
    let results: [TodoistTask]
}

class TodoistManager {
    func fetchTasks(token: String, completion: @escaping ([TodoistTask]?, Error?) -> Void) {
        guard !token.isEmpty else {
            completion([], nil)
            return
        }

        guard let url = URL(string: "https://api.todoist.com/api/v1/tasks") else {
            completion(nil, NSError(domain: "TodoistManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, NSError(domain: "TodoistManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP Response"]))
                return
            }

            guard httpResponse.statusCode == 200 else {
                let msg = "HTTP Status \(httpResponse.statusCode)"
                completion(nil, NSError(domain: "TodoistManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: msg]))
                return
            }

            guard let data = data else {
                completion(nil, NSError(domain: "TodoistManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(TodoistTasksResponse.self, from: data)
                let timedTasks = response.results.filter { $0.due?.isDatetime == true }
                completion(timedTasks, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
}
