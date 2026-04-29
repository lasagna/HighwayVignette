//
//  HighwayModels.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 24..
//

import Foundation

nonisolated struct LocalizedText: Codable, Equatable {
    let hu: String
    let en: String
}

nonisolated struct HighwayInfoResponse: Codable, Equatable {
    let requestId: Int
    let statusCode: String
    let payload: HighwayInfoPayload
}

nonisolated struct HighwayInfoPayload: Codable, Equatable {
    let highwayVignettes: [HighwayVignetteOption]
    let vehicleCategories: [VehicleCategory]
    let counties: [County]
}

nonisolated struct HighwayVignetteOption: Codable, Equatable {
    let vignetteType: [String]
    let vehicleCategory: String
    let cost: Double
    let trxFee: Double
    let sum: Double
}

nonisolated struct VehicleCategory: Codable, Equatable {
    let category: String
    let vignetteCategory: String
    let name: LocalizedText
}

nonisolated struct County: Codable, Equatable, Identifiable {
    let id: String
    let name: String
}

nonisolated struct VehicleInfoResponse: Codable, Equatable {
    let statusCode: String
    let internationalRegistrationCode: String
    let type: String
    let name: String
    let plate: String
    let country: LocalizedText
    let vignetteType: String
}

nonisolated struct HighwayOrderRequest: Codable, Equatable {
    let highwayOrders: [HighwayOrder]
}

nonisolated struct HighwayOrder: Codable, Equatable {
    let type: String
    let category: String
    let cost: Double
}

nonisolated struct HighwayOrderResponse: Codable, Equatable {
    let statusCode: String
    let receivedOrders: [HighwayOrder]
}

nonisolated struct HighwayOrderErrorResponse: Codable, Equatable {
    let statusCode: String
    let message: String
}
