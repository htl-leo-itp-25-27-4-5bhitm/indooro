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
}