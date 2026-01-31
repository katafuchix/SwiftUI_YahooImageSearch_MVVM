//
//  ImageData.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import Foundation
import UIKit

// 表示データ用モデル
// QGridで表示するためにはIdentifiableが必要

struct ImageData: Identifiable, Hashable, Sendable {
    var id = UUID()
    let url: URL

    // URLが同じなら同じデータとみなす設定
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: ImageData, rhs: ImageData) -> Bool {
        lhs.url == rhs.url
    }
}

// エラー
enum ImageError: Error {
    case serverError
    case noData
}
