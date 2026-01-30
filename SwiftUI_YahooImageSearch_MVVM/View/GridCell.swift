//
//  GridCell.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import SwiftUI
import Combine
import QGrid

import SwiftUI

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
                Image(uiImage: container.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill) // 円形にするならfillが綺麗です
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
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

// コードをスッキリさせるためのExtension
extension Image {
    func toThumbnail() -> some View {
        self.resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 100, height: 100)
            .clipShape(Circle())
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
/*

struct GridCell: View {
    
    var imageData: ImageData
    
    // 監視対象にしたいデータに@ObservedObjectをつける。
    @ObservedObject var container: ImageContainer
    
    var body: some View {
        VStack {
            if #available(iOS 15.0, *) {
                AsyncImage(url: imageData.url) { image in
                    image.resizable()
                        .frame(width: 100, height: 100)
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                } placeholder: {
                    ProgressView()
                }
            } else {
                Image(uiImage: container.image)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .scaledToFit()
                    .clipShape(Circle())
            }
        }
    }
}

// ObservableObjectを継承したデータモデル
final class ImageContainer: ObservableObject {

    // @PublishedをつけるとSwiftUIのViewへデータが更新されたことを通知してくれる
    @Published var image = UIImage(systemName: "photo")!

    init(from resource: URL) {
        // ネットワークから画像データ取得
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: resource, completionHandler: { [weak self] data, _, _ in
            guard let imageData = data,
                let networkImage = UIImage(data: imageData) else {
                return
            }

            DispatchQueue.main.async {
                // 宣言時に@Publishedを付けているので、プロパティを更新すればView側に更新が通知される
                self?.image = networkImage
            }
            session.invalidateAndCancel()
        })
        task.resume()
    }
}
*/
