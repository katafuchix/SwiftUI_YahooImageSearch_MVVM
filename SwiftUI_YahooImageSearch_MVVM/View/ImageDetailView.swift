//
//  ImageDetailView.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import SwiftUI

struct ImageDetailView: View {
    let images: [ImageData]
    @Binding var selectedImage: ImageData?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            // imagesが空でないことを確認
            if !images.isEmpty {
                TabView(selection: $selectedImage) {
                    ForEach(images, id: \.url) { data in
                        FullSizeImageView(url: data.url)
                            // ここで確実に型を合わせる（Optionalへのキャスト）
                            .tag(Optional(data))
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .ignoresSafeArea()
            } else {
                Text("データがありません").foregroundColor(.white)
            }

            // 閉じるボタン
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}
