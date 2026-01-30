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
    @StateObject private var viewModel = ImageSearchViewModel()
    
    var body: some View {
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
            
            // ローディング
            ActivityIndicatorView(
                isVisible: $viewModel.showLoadingIndicator,
                type: .growingArc(.black)
            )
            .frame(width: 50.0, height: 50.0)
            
            // 検索結果の表示
            QGrid(viewModel.imageDatas, columns: 3,
                  columnsInLandscape: 5,
                  vSpacing: 16, hSpacing: 8,
                  vPadding: 16, hPadding: 16,
                  isScrollable: true, showScrollIndicators: false
            ) { data in
                GridCell(imageData: data, container: ImageContainer(from: data.url))
            }
        }
    }
}

#Preview {
    ContentView()
}
