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
          "requestId": "12345678",
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

        #expect(response.requestId == "12345678")
        #expect(response.statusCode == "OK")
        #expect(response.payload.highwayVignettes.first?.vehicleCategory == "CAR")
        #expect(response.payload.vehicleCategories.first?.vignetteCategory == "D1")
        #expect(response.payload.counties.first?.id == "YEAR_11")
    }

}
