//
//  HungaryCountyMapData.swift
//  HighwayVignette
//
//  Created by Codex on 2026. 04. 28..
//

import CoreGraphics

struct HungaryCountyMapData: Sendable {
    struct County: Identifiable, Sendable {
        let id: String
        let contours: [[CGPoint]]
    }

    let counties: [County]
    let outlineContours: [[CGPoint]]
    let boundingBox: CGRect
    let adjacencyGraph: [String: Set<String>]

    static let empty = HungaryCountyMapData(
        counties: [],
        outlineContours: [],
        boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1),
        adjacencyGraph: [:]
    )

    var aspectRatio: CGFloat {
        boundingBox.width / boundingBox.height
    }
}
