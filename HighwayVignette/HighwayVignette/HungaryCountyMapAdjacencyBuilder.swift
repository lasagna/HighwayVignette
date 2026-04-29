//
//  HungaryCountyMapAdjacencyBuilder.swift
//  HighwayVignette
//
//  Created by Codex on 2026. 04. 28..
//

import CoreGraphics

enum HungaryCountyMapAdjacencyBuilder {
    private struct LineSegment {
        let start: CGPoint
        let end: CGPoint

        var length: CGFloat {
            hypot(end.x - start.x, end.y - start.y)
        }
    }

    static func build(for counties: [HungaryCountyMapData.County]) -> [String: Set<String>] {
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
}
