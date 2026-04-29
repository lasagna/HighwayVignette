//
//  HighwayVignetteTests.swift
//  HighwayVignetteTests
//
//  Created by Gergo Gombar on 2026. 04. 24..
//

import Foundation
import Testing
@testable import HighwayVignette

struct HighwayVignetteTests {

    @MainActor
    @Test func decodesHighwayInfoResponse() throws {
        let json = """
        {
          "requestId": 12345678,
          "statusCode": "OK",
          "payload": {
            "highwayVignettes": [
              {
                "vignetteType": ["DAY"],
                "vehicleCategory": "CAR",
                "cost": 5150.0,
                "trxFee": 200.0,
                "sum": 5350.0
              }
            ],
            "vehicleCategories": [
              {
                "category": "CAR",
                "vignetteCategory": "D1",
                "name": {
                  "hu": "Szemelygepjarmu",
                  "en": "Car"
                }
              }
            ],
            "counties": [
              {
                "id": "YEAR_11",
                "name": "Bacs-Kiskun"
              }
            ]
          }
        }
        """

        let response = try JSONDecoder().decode(
            HighwayInfoResponse.self,
            from: Data(json.utf8)
        )

        #expect(response.requestId == 12345678)
        #expect(response.statusCode == "OK")
        #expect(response.payload.highwayVignettes.first?.vehicleCategory == "CAR")
        #expect(response.payload.vehicleCategories.first?.vignetteCategory == "D1")
        #expect(response.payload.counties.first?.id == "YEAR_11")
    }

    @MainActor
    @Test func loadsOverviewData() async {
        let viewModel = HighwayViewModel(apiClient: MockHighwayAPIClient())

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.highwayInfo?.payload.highwayVignettes.count == 1)
        #expect(viewModel.vehicleInfo?.plate == "abc-123")
    }

    @Test func resolvesYearlyCountyVignetteForVehicleCategory() {
        let payload = HighwayInfoPayload(
            highwayVignettes: [
                HighwayVignetteOption(
                    vignetteType: ["DAY"],
                    vehicleCategory: "CAR",
                    cost: 5150,
                    trxFee: 200,
                    sum: 5350
                ),
                HighwayVignetteOption(
                    vignetteType: ["YEAR"],
                    vehicleCategory: "CAR",
                    cost: 5450,
                    trxFee: 110,
                    sum: 5560
                ),
            ],
            vehicleCategories: [],
            counties: []
        )

        let option = payload.yearlyCountyVignette(for: "car")

        #expect(option?.cost == 5450)
        #expect(option?.trxFee == 110)
    }

}

private struct MockHighwayAPIClient: HighwayAPIClientProviding {
    func fetchHighwayInfo() async throws -> HighwayInfoResponse {
        HighwayInfoResponse(
            requestId: 12345678,
            statusCode: "OK",
            payload: HighwayInfoPayload(
                highwayVignettes: [
                    HighwayVignetteOption(
                        vignetteType: ["DAY"],
                        vehicleCategory: "CAR",
                        cost: 5150,
                        trxFee: 200,
                        sum: 5350
                    )
                ],
                vehicleCategories: [
                    VehicleCategory(
                        category: "CAR",
                        vignetteCategory: "D1",
                        name: LocalizedText(hu: "Szemelygepjarmu", en: "Car")
                    )
                ],
                counties: [
                    County(id: "YEAR_11", name: "Bacs-Kiskun")
                ]
            )
        )
    }

    func fetchVehicleInfo() async throws -> VehicleInfoResponse {
        VehicleInfoResponse(
            statusCode: "OK",
            internationalRegistrationCode: "H",
            type: "CAR",
            name: "Michael Scott",
            plate: "abc-123",
            country: LocalizedText(hu: "Magyarorszag", en: "Hungary"),
            vignetteType: "D1"
        )
    }

    func submitOrder(_ requestBody: HighwayOrderRequest) async throws -> HighwayOrderResponse {
        HighwayOrderResponse(statusCode: "OK", receivedOrders: requestBody.highwayOrders)
    }
}
