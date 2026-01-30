//
//  ImageData.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import Foundation

// 表示データ用モデル
// QGridで表示するためにはIdentifiableが必要

struct ImageData: Identifiable {
    var id = UUID()
    let url: URL
}

// エラー
enum ImageError: Error {
    case serverError
    case noData
}
