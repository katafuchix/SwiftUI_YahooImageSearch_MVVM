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

            // 呼び出し側はこれだけ（SKPhoto風のシンプルさ）
            PhotoBrowser(images: images, selectedImage: $selectedImage)
                .ignoresSafeArea()

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
