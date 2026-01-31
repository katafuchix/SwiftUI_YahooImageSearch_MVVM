//
//  PhotoBrowser.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import SwiftUI

struct PhotoBrowser: View {
    let images: [ImageData]
    @Binding var selectedImage: ImageData?
    
    var body: some View {
        TabView(selection: $selectedImage) {
            // SKPhotoのように、URLの配列から一気にViewのリストを生成
            ForEach(images, id: \.self) { data in
                SinglePageContent(url: data.url)
                    .tag(data as ImageData?)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

// 内部コンポーネント：ここに「ズーム」「保存」「ロード」を凝縮
private struct SinglePageContent: View {
    let url: URL
    @StateObject private var container: ImageContainer
    
    // ジェスチャー用の状態（削除せずここに保持）
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    init(url: URL) {
        self.url = url
        _container = StateObject(wrappedValue: ImageContainer(from: url))
    }

    var body: some View {
        ZStack {
            Image(uiImage: container.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                // ズームジェスチャー ---
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in scale = lastScale * value }
                        .onEnded { _ in
                            lastScale = scale
                            if scale < 1.0 { withAnimation { scale = 1.0; lastScale = 1.0 } }
                        }
                )
                // ダブルタップリセット ---
                .onTapGesture(count: 2) {
                    withAnimation { scale = 1.0; lastScale = 1.0 }
                }
            
            // 保存完了通知の表示
            if container.showSaveAlert {
                Text(container.alertMessage)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(1) // 最前面に
            }
            // ロード中インジケーター ---
            if !container.isLoaded {
                ProgressView().tint(.white)
            }
        }
        // 保存メニュー（長押し） ---
        .contextMenu {
            if container.isLoaded {
                Button {
                    container.saveToLibrary()
                } label: {
                    Label("画像を保存", systemImage: "square.and.arrow.down")
                }
            }
        }
        .onAppear {
            container.load() // iOS15+でも確実にUIImageを確保
        }
    }
}
