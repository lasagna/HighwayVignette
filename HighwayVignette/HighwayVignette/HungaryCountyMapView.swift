//
//  HungaryCountyMapView.swift
//  HighwayVignette
//
//  Created by Codex on 2026. 04. 27..
//

import SwiftUI

struct HungaryCountyMapView: View {
    let selectedCountyIDs: Set<String>

    private static let mapData = (try? HungaryCountySVGParser.parseBundledMap()) ?? .empty

    var body: some View {
        GeometryReader { geometry in
            let drawingFrame = fittedFrame(in: geometry.size)

            ZStack {
                ForEach(Self.mapData.counties) { county in
                    transformedPath(for: county.contours, in: drawingFrame)
                        .fill(
                            selectedCountyIDs.contains(county.id)
                            ? Color(red: 0.72, green: 1.0, blue: 0.0)
                            : Color(red: 0.78, green: 0.87, blue: 0.92)
                        )

                    transformedPath(for: county.contours, in: drawingFrame)
                        .stroke(.white, lineWidth: 1.6)
                }

                transformedPath(for: Self.mapData.outlineContours, in: drawingFrame)
                    .stroke(.white, lineWidth: 2.2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(Self.mapData.aspectRatio, contentMode: .fit)
        .background(Color.clear)
    }

    private func fittedFrame(in size: CGSize) -> CGRect {
        guard
            size.width > 0,
            size.height > 0,
            Self.mapData.boundingBox.width > 0,
            Self.mapData.boundingBox.height > 0
        else {
            return .zero
        }

        let scale = min(
            size.width / Self.mapData.boundingBox.width,
            size.height / Self.mapData.boundingBox.height
        )

        let width = Self.mapData.boundingBox.width * scale
        let height = Self.mapData.boundingBox.height * scale

        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }

    private func transformedPath(for contours: [[CGPoint]], in frame: CGRect) -> Path {
        var path = Path()

        guard
            frame.width > 0,
            frame.height > 0,
            Self.mapData.boundingBox.width > 0,
            Self.mapData.boundingBox.height > 0
        else {
            return path
        }

        for contour in contours where !contour.isEmpty {
            let first = transformedPoint(contour[0], in: frame)
            path.move(to: first)

            for point in contour.dropFirst() {
                path.addLine(to: transformedPoint(point, in: frame))
            }

            path.closeSubpath()
        }

        return path
    }

    private func transformedPoint(_ point: CGPoint, in frame: CGRect) -> CGPoint {
        let normalizedX = (point.x - Self.mapData.boundingBox.minX) / Self.mapData.boundingBox.width
        let normalizedY = (point.y - Self.mapData.boundingBox.minY) / Self.mapData.boundingBox.height

        return CGPoint(
            x: frame.minX + (normalizedX * frame.width),
            y: frame.minY + (normalizedY * frame.height)
        )
    }
}

private struct HungaryCountySVGParser {
    struct ParsedCounty: Identifiable {
        let id: String
        let contours: [[CGPoint]]
    }

    struct ParsedMap {
        let counties: [ParsedCounty]
        let outlineContours: [[CGPoint]]
        let boundingBox: CGRect

        static let empty = ParsedMap(
            counties: [],
            outlineContours: [],
            boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1)
        )

        var aspectRatio: CGFloat {
            boundingBox.width / boundingBox.height
        }
    }

    static func parseBundledMap() throws -> ParsedMap {
        guard let url = Bundle.main.url(forResource: "HU_counties_blank", withExtension: "svg") else {
            throw SVGParserError.missingResource
        }

        let svg = try String(contentsOf: url, encoding: .utf8)
        return try parse(svg: svg)
    }

    static func parse(svg: String) throws -> ParsedMap {
        let expression = try NSRegularExpression(
            pattern: #"<path\s+[^>]*?d="([^"]+)"\s+[^>]*?id="([^"]+)""#,
            options: [.dotMatchesLineSeparators]
        )

        let svgRange = NSRange(svg.startIndex..., in: svg)
        let matches = expression.matches(in: svg, options: [], range: svgRange)

        guard !matches.isEmpty else {
            throw SVGParserError.noPathsFound
        }

        var counties: [ParsedCounty] = []
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
                counties.append(ParsedCounty(id: id, contours: contours))
            }
        }

        guard let outlineContours else {
            throw SVGParserError.missingOutline
        }

        let box = boundingBox(for: outlineContours)

        return ParsedMap(
            counties: counties,
            outlineContours: outlineContours,
            boundingBox: box
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

    enum SVGParserError: Error {
        case missingResource
        case noPathsFound
        case missingOutline
        case invalidPathData
        case unsupportedCommand(String)
        case invalidCoordinate(String, String)
    }
}

#Preview {
    HungaryCountyMapView(selectedCountyIDs: ["baranya", "fejer", "gyms", "pest"])
        .frame(height: 220)
        .padding()
        .background(Color(.systemGroupedBackground))
}
