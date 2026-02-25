//
//  Product.swift
//  indooroApp
//
//  Created by Erik Bergmair on 07.02.26.
//

import Foundation

struct Product: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let price: Double
    let layoutCode: String // z.B. "310/1/1/1"

    var categoryCode: String {
        layoutCode.split(separator: "/").first.map(String.init) ?? "000"
    }

    var categoryName: String {
        switch categoryCode {
        case "310":
            return "Obst & Gemüse"
        case "420":
            return "Tomatenprodukte"
        case "430":
            return "Pasta"
        case "440":
            return "Grundnahrung"
        case "450":
            return "Öl & Essig"
        case "470":
            return "Snacks"
        case "510":
            return "Getränke"
        case "520":
            return "Milchprodukte"
        case "525":
            return "Käse & Butter"
        case "530":
            return "Tiefkühlkost"
        case "610":
            return "Haushalt & Pflege"
        case "640":
            return "Papierwaren"
        default:
            return "Kategorie \(categoryCode)"
        }
    }

    var categorySymbol: String {
        switch categoryCode {
        case "310":
            return "leaf"
        case "420":
            return "carton"
        case "430":
            return "fork.knife"
        case "440":
            return "bag"
        case "450":
            return "drop"
        case "470":
            return "takeoutbag.and.cup.and.straw"
        case "510":
            return "cup.and.saucer"
        case "520", "525":
            return "refrigerator"
        case "530":
            return "snowflake"
        case "610":
            return "sparkles"
        case "640":
            return "toiletpaper"
        default:
            return "shippingbox"
        }
    }
}
