//
//  HighwayAPIClient.swift
//  HighwayVignette
//
//  Created by Codex on 2026. 04. 24..
//

import Foundation

protocol HighwayAPIClientProviding {
    func fetchHighwayInfo() async throws -> HighwayInfoResponse
    func fetchVehicleInfo() async throws -> VehicleInfoResponse
    func submitOrder(_ requestBody: HighwayOrderRequest) async throws -> HighwayOrderResponse
}

struct HighwayAPIClient {
    let baseURL: URL
    let session: URLSession
    let decoder: JSONDecoder
    let encoder: JSONEncoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    func fetchHighwayInfo() async throws -> HighwayInfoResponse {
        try await performRequest(
            path: "/v1/highway/info",
            method: "GET",
            responseType: HighwayInfoResponse.self
        )
    }

    func fetchVehicleInfo() async throws -> VehicleInfoResponse {
        try await performRequest(
            path: "/v1/highway/vehicle",
            method: "GET",
            responseType: VehicleInfoResponse.self
        )
    }

    func submitOrder(_ requestBody: HighwayOrderRequest) async throws -> HighwayOrderResponse {
        let body = try encoder.encode(requestBody)

        do {
            return try await performRequest(
                path: "/v1/highway/order",
                method: "POST",
                body: body,
                responseType: HighwayOrderResponse.self
            )
        } catch let error as HighwayAPIError {
            if case let .httpError(statusCode, data) = error, statusCode == 400 {
                let orderError = try decoder.decode(HighwayOrderErrorResponse.self, from: data)
                throw HighwayAPIError.orderRejected(orderError)
            }

            throw error
        }
    }

    private func performRequest<Response: Decodable>(
        path: String,
        method: String,
        body: Data? = nil,
        responseType: Response.Type
    ) async throws -> Response {
        let request = try makeRequest(path: path, method: method, body: body)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HighwayAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw HighwayAPIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw HighwayAPIError.decodingFailed(error)
        }
    }

    private func makeRequest(path: String, method: String, body: Data?) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw HighwayAPIError.invalidURL(path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}

extension HighwayAPIClient: HighwayAPIClientProviding {}

enum HighwayAPIError: Error, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingFailed(Error)
    case orderRejected(HighwayOrderErrorResponse)

    var errorDescription: String? {
        switch self {
        case let .invalidURL(path):
            return "Invalid URL for path: \(path)"
        case .invalidResponse:
            return "The server returned an invalid response."
        case let .httpError(statusCode, _):
            return "Unexpected HTTP status code: \(statusCode)"
        case let .decodingFailed(error):
            return "Failed to decode server response: \(error.localizedDescription)"
        case let .orderRejected(response):
            return response.message
        }
    }
}
