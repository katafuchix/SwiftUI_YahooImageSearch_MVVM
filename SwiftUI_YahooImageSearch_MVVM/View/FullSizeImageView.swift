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

    // ズームと移動のための状態変数
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
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
                // 拡大と移動の適用
                .scaleEffect(scale)
                .offset(offset)
                // ジェスチャー：ピンチ（拡大）
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            // 前回のスケールを基準に計算
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            // 指を離した時のスケールを保存
                            lastScale = scale
                            // 小さくなりすぎたら元に戻す
                            if scale < 1.0 {
                                withAnimation {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                        }
                )
                // ダブルタップでリセットする機能
                .onTapGesture(count: 2) {
                    withAnimation {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
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
