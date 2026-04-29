//
//  HungaryCountyMapData.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 28..
//

import CoreGraphics

nonisolated struct HungaryCountyMapData: Sendable {
    nonisolated struct County: Identifiable, Sendable {
        let id: String
        let contours: [[CGPoint]]
    }

    let counties: [County]
    let outlineContours: [[CGPoint]]
    let boundingBox: CGRect
    let adjacencyGraph: [String: Set<String>]

    nonisolated static let empty = HungaryCountyMapData(
        counties: [],
        outlineContours: [],
        boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1),
        adjacencyGraph: [:]
    )

    nonisolated var aspectRatio: CGFloat {
        boundingBox.width / boundingBox.height
    }
}
