//
//  GridCell.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import SwiftUI
import Combine
import QGrid

struct GridCell: View {
    var imageData: ImageData
    @ObservedObject var container: ImageContainer
    
    var body: some View {
        VStack {
            if #available(iOS 15.0, *) {
                // デフォルトのAsyncImageを使用
                AsyncImage(url: imageData.url) { image in
                    image.toThumbnail()
                } placeholder: {
                    ProgressView()
                }
            } else {
                // 自作のコンテナ経由で表示
                Image(uiImage: container.image).toThumbnail()
            }
        }
        // セルが表示されたタイミングでロードを開始する（init内ではなく）
        .onAppear {
            if #unavailable(iOS 15.0) {
                container.load()
            }
        }
    }
}
