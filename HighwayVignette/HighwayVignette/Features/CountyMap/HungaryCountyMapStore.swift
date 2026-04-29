//
//  HungaryCountyMapStore.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 28..
//

import Foundation

actor HungaryCountyMapStore {
    static let shared = HungaryCountyMapStore()
    static let previewData = (try? HungaryCountySVGParser.parseBundledMap()) ?? .empty

    private var cachedMapData: HungaryCountyMapData?
    private var loadingTask: Task<HungaryCountyMapData, Error>?

    func loadMapDataIfNeeded() async throws -> HungaryCountyMapData {
        if let cachedMapData {
            return cachedMapData
        }

        if let loadingTask {
            return try await loadingTask.value
        }

        let loadingTask = Task(priority: .utility) {
            try HungaryCountySVGParser.parseBundledMap()
        }
        self.loadingTask = loadingTask

        do {
            let mapData = try await loadingTask.value
            cachedMapData = mapData
            self.loadingTask = nil
            return mapData
        } catch {
            self.loadingTask = nil
            throw error
        }
    }
}
