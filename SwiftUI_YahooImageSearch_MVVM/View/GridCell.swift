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

// ObservableObjectを継承したデータモデル
final class ImageContainer: ObservableObject {

    // @PublishedをつけるとSwiftUIのViewへデータが更新されたことを通知してくれる
    @Published var image = UIImage(systemName: "photo")!
    private let url: URL
    private var isLoaded = false

    init(from url: URL) {
        self.url = url
    }

    func load() {
        guard !isLoaded else { return } // 二重ロード防止
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let networkImage = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                // 宣言時に@Publishedを付けているので、プロパティを更新すればView側に更新が通知される
                self?.image = networkImage
                self?.isLoaded = true
            }
        }.resume()
    }
}
