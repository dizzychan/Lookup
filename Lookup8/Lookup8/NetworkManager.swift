//
//  NetworkManager.swift
//  Lookup8
//
//  Created by Wangzhen Wu on 30/04/2025.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case serverError(String)
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://localhost:3000/api"
    private let openLibraryBaseURL = "https://openlibrary.org"
    private let gutendexBaseURL = "https://gutendex.com"
    
    private init() {}
    
    func register(username: String, password: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/users/register") else {
            throw NetworkError.invalidURL
        }
        
        let parameters = [
            "username": username,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        if httpResponse.statusCode != 201 {
            if let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)["message"] {
                throw NetworkError.serverError(errorMessage)
            }
            throw NetworkError.serverError("Unknown error")
        }
        
        return true
    }
    
    func login(username: String, password: String) async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)/users/login") else {
            throw NetworkError.invalidURL
        }
        
        let parameters = [
            "username": username,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)["message"] {
                throw NetworkError.serverError(errorMessage)
            }
            throw NetworkError.serverError("Unknown error")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NetworkError.invalidData
        }
        
        return json
    }
    
    // MARK: - Gutendex API
    
    func searchBooks(query: String) async throws -> [SourceItem] {
        guard let url = URL(string: "\(gutendexBaseURL)/books?search=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw NetworkError.serverError("Failed to fetch books")
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(GutendexResponse.self, from: data)
        
        return result.results.map { book in
            SourceItem(
                title: book.title,
                author: book.authors.first?.name ?? "Unknown Author",
                detailURL: URL(string: book.formats["text/html"] ?? book.formats["text/plain"] ?? "https://www.gutenberg.org/ebooks/\(book.id)")!,
                coverURL: URL(string: book.formats["image/jpeg"] ?? "")
            )
        }
    }
    
    func fetchBookContent(url: URL) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw NetworkError.serverError("Failed to fetch book content")
        }
        
        if let htmlString = String(data: data, encoding: .utf8) {
            return htmlString
        }
        
        throw NetworkError.invalidData
    }
}

// MARK: - Gutendex Models

struct GutendexResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [GutendexBook]
}

struct GutendexBook: Codable {
    let id: Int
    let title: String
    let authors: [GutendexAuthor]
    let formats: [String: String]
}

struct GutendexAuthor: Codable {
    let name: String
    let birthYear: Int?
    let deathYear: Int?
    
    enum CodingKeys: String, CodingKey {
        case name
        case birthYear = "birth_year"
        case deathYear = "death_year"
    }
}
