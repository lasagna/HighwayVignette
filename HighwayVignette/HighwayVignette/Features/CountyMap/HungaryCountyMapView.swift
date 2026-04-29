//
//  HungaryCountyMapView.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 27..
//

import SwiftUI

struct HungaryCountyMapView: View {
    let mapData: HungaryCountyMapData
    let selectedCountyIDs: Set<String>

    var body: some View {
        GeometryReader { geometry in
            let drawingFrame = fittedFrame(in: geometry.size)

            ZStack {
                ForEach(mapData.counties) { county in
                    transformedPath(for: county.contours, in: drawingFrame)
                        .fill(
                            selectedCountyIDs.contains(county.id)
                            ? Color(red: 0.72, green: 1.0, blue: 0.0)
                            : Color(red: 0.78, green: 0.87, blue: 0.92)
                        )

                    transformedPath(for: county.contours, in: drawingFrame)
                        .stroke(.white, lineWidth: 1.6)
                }

                transformedPath(for: mapData.outlineContours, in: drawingFrame)
                    .stroke(.white, lineWidth: 2.2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(mapData.aspectRatio, contentMode: .fit)
        .background(Color.clear)
    }

    private func fittedFrame(in size: CGSize) -> CGRect {
        guard
            size.width > 0,
            size.height > 0,
            mapData.boundingBox.width > 0,
            mapData.boundingBox.height > 0
        else {
            return .zero
        }

        let scale = min(
            size.width / mapData.boundingBox.width,
            size.height / mapData.boundingBox.height
        )

        let width = mapData.boundingBox.width * scale
        let height = mapData.boundingBox.height * scale

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
            mapData.boundingBox.width > 0,
            mapData.boundingBox.height > 0
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
        let normalizedX = (point.x - mapData.boundingBox.minX) / mapData.boundingBox.width
        let normalizedY = (point.y - mapData.boundingBox.minY) / mapData.boundingBox.height

        return CGPoint(
            x: frame.minX + (normalizedX * frame.width),
            y: frame.minY + (normalizedY * frame.height)
        )
    }
}

#Preview {
    HungaryCountyMapView(
        mapData: HungaryCountyMapStore.previewData,
        selectedCountyIDs: ["baranya", "fejer", "gyms", "pest"]
    )
    .frame(height: 220)
    .padding()
    .background(Color(.systemGroupedBackground))
}
