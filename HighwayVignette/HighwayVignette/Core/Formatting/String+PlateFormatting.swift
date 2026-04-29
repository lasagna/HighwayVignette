//
//  String+PlateFormatting.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 28..
//

import Foundation

extension String {
    var formattedPlate: String {
        replacingOccurrences(of: "-", with: " ").uppercased()
    }
}

extension Optional where Wrapped == String {
    var formattedPlateOrPlaceholder: String {
        self?.formattedPlate ?? "-"
    }
}
