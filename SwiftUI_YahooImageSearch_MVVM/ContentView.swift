//
//  ContentView.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import SwiftUI
import QGrid
import ActivityIndicatorView

struct ContentView: View {
    // ViewModelを初期化
    @StateObject private var viewModel = ImageSearchViewModel(searchProtocol: ImageLoader())
    
    var body: some View {
        // ZStackで背面と前面を分ける
        ZStack {
            // 背面：メインコンテンツ
            VStack {
                Spacer().frame(height: 20)
                
                // 検索バー
                HStack(spacing: 20) {
                    Spacer()
                    TextField("検索キーワード", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Spacer()
                }
                
                // 検索ボタン
                Button(action: {
                    viewModel.search()
                }) {
                    Text("Search")
                }
                .disabled(!viewModel.isButtonEnabled)
                
                Spacer()
                
                if viewModel.imageDatas.isEmpty && viewModel.hasSearched && !viewModel.showLoadingIndicator {
                        // 1. 検索結果が空の場合
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("\"\(viewModel.searchText)\" に一致する画像は見つかりませんでした")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 検索結果の表示
                    QGrid(viewModel.imageDatas, columns: 3,
                          columnsInLandscape: 5,
                          vSpacing: 16, hSpacing: 8,
                          vPadding: 16, hPadding: 16,
                          isScrollable: true, showScrollIndicators: false
                    ) { data in
                        GridCell(imageData: data, container: ImageContainer(from: data.url))
                        .onTapGesture {
                            // タップした画像をセットしてフラグをオン
                            viewModel.selectedImageData = data
                            viewModel.isShowingDetail = true
                        }
                    }
                    .fullScreenCover(isPresented: $viewModel.isShowingDetail) {
                        // 全画面表示を呼び出し
                        ImageDetailView(images: viewModel.imageDatas, selectedImage: $viewModel.selectedImageData)
                    }
                }
            }
            
            // 前面：ローディング（isVisibleがtrueの時だけ中央に表示される）
            if viewModel.showLoadingIndicator {
                ActivityIndicatorView(
                    isVisible: $viewModel.showLoadingIndicator,
                    type: .growingArc(.black)
                )
                .frame(width: 50.0, height: 50.0)
                // ZStack内ではデフォルトで中央配置になります
            }
        }
    }
}

#Preview {
    ContentView()
}
