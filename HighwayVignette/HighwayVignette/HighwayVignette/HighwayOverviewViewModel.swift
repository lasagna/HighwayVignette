//
//  HighwayOverviewViewModel.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 24..
//

import Foundation
import Observation

@MainActor
@Observable
final class HighwayOverviewViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private let apiClient: any HighwayAPIClientProviding

    var state: LoadState = .idle
    var highwayInfo: HighwayInfoResponse?
    var vehicleInfo: VehicleInfoResponse?

    init(apiClient: any HighwayAPIClientProviding) {
        self.apiClient = apiClient
    }

    var isLoading: Bool {
        if case .loading = state {
            return true
        }

        return false
    }

    var errorMessage: String? {
        if case let .failed(message) = state {
            return message
        }

        return nil
    }

    func load() async {
        guard !isLoading else { return }

        state = .loading

        do {
            async let highwayInfo = apiClient.fetchHighwayInfo()
            async let vehicleInfo = apiClient.fetchVehicleInfo()

            self.highwayInfo = try await highwayInfo
            self.vehicleInfo = try await vehicleInfo
            state = .loaded
        } catch {
            highwayInfo = nil
            vehicleInfo = nil
            state = .failed(error.localizedDescription)
        }
    }
}
