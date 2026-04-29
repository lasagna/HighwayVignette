//
//  HungaryCountyMapStore.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 28..
//

import Foundation
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

actor HungaryCountyMapStore {
    static let shared = HungaryCountyMapStore()
    static let previewData = (try? HungaryCountySVGParser.parseBundledMap()) ?? .empty

    private var cachedMapData: HungaryCountyMapData?
    private var loadingTask: Task<HungaryCountyMapData, Error>?

    func loadMapData() async throws -> HungaryCountyMapData {
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

private struct HungaryCountySVGParser {
    private struct LineSegment {
        let start: CGPoint
        let end: CGPoint

        var length: CGFloat {
            hypot(end.x - start.x, end.y - start.y)
        }
    }

    static func parseBundledMap() throws -> HungaryCountyMapData {
        guard let url = Bundle.main.url(forResource: "HU_counties_blank", withExtension: "svg") else {
            throw SVGParserError.missingResource
        }

        let svg = try String(contentsOf: url, encoding: .utf8)
        return try parse(svg: svg)
    }

    static func parse(svg: String) throws -> HungaryCountyMapData {
        let expression = try NSRegularExpression(
            pattern: #"<path\s+[^>]*?d="([^"]+)"\s+[^>]*?id="([^"]+)""#,
            options: [.dotMatchesLineSeparators]
        )

        let svgRange = NSRange(svg.startIndex..., in: svg)
        let matches = expression.matches(in: svg, options: [], range: svgRange)

        guard !matches.isEmpty else {
            throw SVGParserError.noPathsFound
        }

        var counties: [HungaryCountyMapData.County] = []
        var outlineContours: [[CGPoint]]?

        for match in matches {
            guard
                let dRange = Range(match.range(at: 1), in: svg),
                let idRange = Range(match.range(at: 2), in: svg)
            else {
                continue
            }

            let pathData = String(svg[dRange])
            let id = String(svg[idRange])
            let contours = try parsePathData(pathData)

            if id == "mo" {
                outlineContours = contours
            } else {
                counties.append(HungaryCountyMapData.County(id: id, contours: contours))
            }
        }

        guard let outlineContours else {
            throw SVGParserError.missingOutline
        }

        let box = boundingBox(for: outlineContours)
        let adjacencyGraph = buildAdjacencyGraph(for: counties)

        return HungaryCountyMapData(
            counties: counties,
            outlineContours: outlineContours,
            boundingBox: box,
            adjacencyGraph: adjacencyGraph
        )
    }

    private static func parsePathData(_ pathData: String) throws -> [[CGPoint]] {
        let tokens = pathData
            .replacingOccurrences(of: ",", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        var contours: [[CGPoint]] = []
        var currentContour: [CGPoint] = []
        var currentCommand: String?
        var index = 0

        while index < tokens.count {
            let token = tokens[index]

            if token == "M" || token == "L" || token == "z" || token == "Z" {
                currentCommand = token
                index += 1

                if token == "z" || token == "Z" {
                    if !currentContour.isEmpty {
                        contours.append(currentContour)
                        currentContour = []
                    }
                }

                continue
            }

            guard let currentCommand else {
                throw SVGParserError.invalidPathData
            }

            guard currentCommand == "M" || currentCommand == "L" else {
                throw SVGParserError.unsupportedCommand(currentCommand)
            }

            guard index + 1 < tokens.count else {
                throw SVGParserError.invalidPathData
            }

            guard
                let x = Double(tokens[index]),
                let y = Double(tokens[index + 1])
            else {
                throw SVGParserError.invalidCoordinate(tokens[index], tokens[index + 1])
            }

            if currentCommand == "M", !currentContour.isEmpty {
                contours.append(currentContour)
                currentContour = []
            }

            currentContour.append(CGPoint(x: x, y: y))
            index += 2
        }

        if !currentContour.isEmpty {
            contours.append(currentContour)
        }

        return contours
    }

    private static func boundingBox(for contours: [[CGPoint]]) -> CGRect {
        let points = contours.flatMap { $0 }

        guard let first = points.first else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }

        var minX = first.x
        var maxX = first.x
        var minY = first.y
        var maxY = first.y

        for point in points.dropFirst() {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private static func buildAdjacencyGraph(for counties: [HungaryCountyMapData.County]) -> [String: Set<String>] {
        var graph = Dictionary(uniqueKeysWithValues: counties.map { ($0.id, Set<String>()) })

        for lhsIndex in counties.indices {
            for rhsIndex in counties.indices where rhsIndex > lhsIndex {
                let lhs = counties[lhsIndex]
                let rhs = counties[rhsIndex]

                if areNeighbors(lhs, rhs) {
                    graph[lhs.id, default: []].insert(rhs.id)
                    graph[rhs.id, default: []].insert(lhs.id)
                }
            }
        }

        return graph
    }

    private static func areNeighbors(_ lhs: HungaryCountyMapData.County, _ rhs: HungaryCountyMapData.County) -> Bool {
        let tolerance: CGFloat = 0.15
        let minimumSharedBorderLength: CGFloat = 6.0
        let lhsSegments = segments(for: lhs.contours)
        let rhsSegments = segments(for: rhs.contours)
        var sharedBorderLength: CGFloat = 0

        for lhsSegment in lhsSegments {
            for rhsSegment in rhsSegments {
                let overlapLength = sharedBorderOverlapLength(
                    lhsSegment,
                    rhsSegment,
                    tolerance: tolerance
                )

                if overlapLength > 0 {
                    sharedBorderLength += overlapLength

                    if sharedBorderLength >= minimumSharedBorderLength {
                        return true
                    }
                }
            }
        }

        return false
    }

    private static func segments(for contours: [[CGPoint]]) -> [LineSegment] {
        var result: [LineSegment] = []

        for contour in contours where contour.count > 1 {
            for index in contour.indices {
                let nextIndex = contour.index(after: index)
                let endIndex = nextIndex == contour.endIndex ? contour.startIndex : nextIndex
                let segment = LineSegment(start: contour[index], end: contour[endIndex])

                if segment.length > 0 {
                    result.append(segment)
                }
            }
        }

        return result
    }

    private static func sharedBorderOverlapLength(
        _ lhs: LineSegment,
        _ rhs: LineSegment,
        tolerance: CGFloat
    ) -> CGFloat {
        guard areCollinear(lhs, rhs, tolerance: tolerance) else {
            return 0
        }

        let direction = CGPoint(
            x: lhs.end.x - lhs.start.x,
            y: lhs.end.y - lhs.start.y
        )
        let axisLength = hypot(direction.x, direction.y)

        guard axisLength > 0 else {
            return 0
        }

        let unit = CGPoint(x: direction.x / axisLength, y: direction.y / axisLength)
        let lhsRange = projectedRange(for: lhs, unit: unit)
        let rhsRange = projectedRange(for: rhs, unit: unit)
        let overlap = min(lhsRange.upperBound, rhsRange.upperBound) - max(lhsRange.lowerBound, rhsRange.lowerBound)

        return overlap > tolerance ? overlap : 0
    }

    private static func areCollinear(
        _ lhs: LineSegment,
        _ rhs: LineSegment,
        tolerance: CGFloat
    ) -> Bool {
        let lhsVector = CGPoint(x: lhs.end.x - lhs.start.x, y: lhs.end.y - lhs.start.y)
        let rhsVector = CGPoint(x: rhs.end.x - rhs.start.x, y: rhs.end.y - rhs.start.y)
        let lhsLength = hypot(lhsVector.x, lhsVector.y)
        let rhsLength = hypot(rhsVector.x, rhsVector.y)

        guard lhsLength > 0, rhsLength > 0 else {
            return false
        }

        let normalizedCross = abs(cross(lhsVector, rhsVector)) / (lhsLength * rhsLength)

        guard normalizedCross <= tolerance else {
            return false
        }

        let offsetVector = CGPoint(x: rhs.start.x - lhs.start.x, y: rhs.start.y - lhs.start.y)
        let offsetDistance = abs(cross(lhsVector, offsetVector)) / lhsLength

        return offsetDistance <= tolerance
    }

    private static func projectedRange(
        for segment: LineSegment,
        unit: CGPoint
    ) -> ClosedRange<CGFloat> {
        let startProjection = dot(segment.start, unit)
        let endProjection = dot(segment.end, unit)
        let lower = min(startProjection, endProjection)
        let upper = max(startProjection, endProjection)

        return lower...upper
    }

    private static func dot(_ point: CGPoint, _ unit: CGPoint) -> CGFloat {
        (point.x * unit.x) + (point.y * unit.y)
    }

    private static func cross(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        (lhs.x * rhs.y) - (lhs.y * rhs.x)
    }

    enum SVGParserError: Error {
        case missingResource
        case noPathsFound
        case missingOutline
        case invalidPathData
        case unsupportedCommand(String)
        case invalidCoordinate(String, String)
    }
}
