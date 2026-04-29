//
//  HungaryCountySVGParser.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 28..
//

import Foundation
import CoreGraphics

nonisolated enum HungaryCountySVGParser {
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

        return HungaryCountyMapData(
            counties: counties,
            outlineContours: outlineContours,
            boundingBox: boundingBox(for: outlineContours),
            adjacencyGraph: HungaryCountyMapAdjacencyBuilder.build(for: counties)
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

                if token == "z" || token == "Z", !currentContour.isEmpty {
                    contours.append(currentContour)
                    currentContour = []
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

    enum SVGParserError: Error {
        case missingResource
        case noPathsFound
        case missingOutline
        case invalidPathData
        case unsupportedCommand(String)
        case invalidCoordinate(String, String)
    }
}
