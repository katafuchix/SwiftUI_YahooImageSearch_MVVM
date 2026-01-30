//
//  Image+extended.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//
import SwiftUI

extension Image {
    func toThumbnail() -> some View {
        self.resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 100, height: 100)
            .clipShape(Circle())
    }
}
