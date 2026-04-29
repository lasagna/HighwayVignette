//
//  Double+PriceFormatting.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 28..
//

import Foundation

extension Double {
    var formattedForints: String {
        let amount = PriceFormatter.currency.string(from: NSNumber(value: self)) ?? "\(Int(self))"
        return "\(amount) Ft"
    }
}

private enum PriceFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}
