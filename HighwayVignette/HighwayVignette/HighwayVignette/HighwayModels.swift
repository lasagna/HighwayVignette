//
//  HighwayModels.swift
//  HighwayVignette
//
//  Created by Codex on 2026. 04. 24..
//

import Foundation

struct LocalizedText: Codable, Equatable {
    let hu: String
    let en: String
}

struct HighwayInfoResponse: Codable, Equatable {
    let requestId: String
    let statusCode: String
    let payload: HighwayInfoPayload
}

struct HighwayInfoPayload: Codable, Equatable {
    let highwayVignettes: [HighwayVignetteOption]
    let vehicleCategories: [VehicleCategory]
    let counties: [County]
}

struct HighwayVignetteOption: Codable, Equatable {
    let vignetteType: [String]
    let vehicleCategory: String
    let cost: Double
    let trxFee: Double
    let sum: Double
}

struct VehicleCategory: Codable, Equatable {
    let category: String
    let vignetteCategory: String
    let name: LocalizedText
}

struct County: Codable, Equatable, Identifiable {
    let id: String
    let name: String
}

struct VehicleInfoResponse: Codable, Equatable {
    let statusCode: String
    let internationalRegistrationCode: String
    let type: String
    let name: String
    let plate: String
    let country: LocalizedText
    let vignetteType: String
}

struct HighwayOrderRequest: Codable, Equatable {
    let highwayOrders: [HighwayOrder]
}

struct HighwayOrder: Codable, Equatable {
    let type: String
    let category: String
    let cost: Double
}

struct HighwayOrderResponse: Codable, Equatable {
    let statusCode: String
    let receivedOrders: [HighwayOrder]
}

struct HighwayOrderErrorResponse: Codable, Equatable {
    let statusCode: String
    let message: String
}
