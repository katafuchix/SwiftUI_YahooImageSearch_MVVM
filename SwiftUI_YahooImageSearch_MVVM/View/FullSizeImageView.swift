//
//  FullSizeImageView.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import SwiftUI

struct FullSizeImageView: View {
    let url: URL
    @StateObject private var container: ImageContainer

    init(url: URL) {
        self.url = url
        _container = StateObject(wrappedValue: ImageContainer(from: url))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: container.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // ロード完了後、長押しで保存メニューを表示
                .contextMenu {
                    if container.isLoaded {
                        Button {
                            UIImageWriteToSavedPhotosAlbum(container.image, nil, nil, nil)
                        } label: {
                            Label("画像を保存", systemImage: "square.and.arrow.down")
                        }
                    }
                }
            // フラグが false（未ロード）の間だけ ProgressView を出す
            if !container.isLoaded {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .onAppear {
            container.load()
        }
    }
}
