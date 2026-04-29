//
//  YearlyCountySelectionSupport.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 28..
//

import Foundation

enum YearlyCountyIdentityMapper {
    static let countyIDByName: [String: String] = [
        "Bács-Kiskun": "bk",
        "Baranya": "baranya",
        "Borsod-Abaúj-Zemplén": "baz",
        "Budapest": "budapest",
        "Csongrád": "csongrad",
        "Fejér": "fejer",
        "Győr-Moson-Sopron": "gyms",
        "Hajdú-Bihar": "hb",
        "Heves": "heves",
        "Jász-Nagykun-Szolnok": "jnsz",
        "Komárom-Esztergom": "ke",
        "Nógrád": "nograd",
        "Pest": "pest",
        "Somogy": "somogy",
        "Szabolcs-Szatmár-Bereg": "szszb",
        "Tolna": "tolna",
        "Vas": "vas",
        "Veszprém": "veszprem",
        "Zala": "zala",
    ]

    static let countyNameByID: [String: String] = Dictionary(
        uniqueKeysWithValues: countyIDByName.map { ($1, $0) }
    )
}

enum YearlyCountySelectionValidator {
    static func disconnectedSelectedCountyNames(
        selectedCountyIDs: Set<String>,
        adjacencyGraph: [String: Set<String>]
    ) -> [String] {
        guard selectedCountyIDs.count > 1, let startID = selectedCountyIDs.first else {
            return []
        }

        var visited: Set<String> = []
        var queue: [String] = [startID]

        while let currentID = queue.first {
            queue.removeFirst()

            guard !visited.contains(currentID) else {
                continue
            }

            visited.insert(currentID)

            for neighbor in adjacencyGraph[currentID, default: []] where selectedCountyIDs.contains(neighbor) {
                if !visited.contains(neighbor) {
                    queue.append(neighbor)
                }
            }
        }

        return selectedCountyIDs
            .subtracting(visited)
            .compactMap { YearlyCountyIdentityMapper.countyNameByID[$0] }
            .sorted()
    }
}
