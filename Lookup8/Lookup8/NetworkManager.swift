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
}
