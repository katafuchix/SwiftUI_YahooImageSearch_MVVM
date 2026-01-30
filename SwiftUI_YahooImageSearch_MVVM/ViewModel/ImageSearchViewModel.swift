//
//  ImageSearchViewModel.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import SwiftUI
import Combine

@MainActor // await から戻ってきた後の処理は自動的にメインスレッドで実行
class ImageSearchViewModel: ObservableObject {
    // Viewから参照する状態
    @Published var searchText = ""
    @Published var imageDatas = [ImageData]()
    @Published var isLoading = false
    @Published var showLoadingIndicator = false
    @Published var isButtonEnabled = false
    // 検索後の状態を整理するためのフラグを追加
    @Published var hasSearched = false // 一度でも検索を実行したか
    @Published var selectedImageData: ImageData? = nil // これが非nilなら全画面表示
    @Published var isShowingDetail = false           // 全画面表示のフラグ
    
    private var cancellables = Set<AnyCancellable>()
    private let imageLoader = ImageLoader()
    
    init() {
        // テキストの変更を監視してボタンの有効化を判定
        $searchText
            .map { $0.count >= 3 }
            .assign(to: \.isButtonEnabled, on: self)
            .store(in: &cancellables)
        
        // Debounce機能の追加
        $searchText
            .dropFirst() // 初期値（空文字）での発火を防ぐ
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main) // 0.5秒待つ
            .removeDuplicates() // 同じ文字での連続発火を防ぐ
            .sink { [weak self] _ in
                // 文字数が足りている場合のみ、自動で検索を実行
                if self?.isButtonEnabled == true {
                    self?.search()
                }
            }
            .store(in: &cancellables)
    }
    
    // 検索実行
    func search() {
        self.imageDatas = []
        // キーボードを下げる（Viewから呼ぶのが一般的ですがVMにトリガーを持たせることも可能）
        UIApplication.shared.endEditing()
        
        if #available(iOS 15.0, *) {
            Task {
                await performSearchAsync()
            }
        } else {
            performSearchLegacy()
        }
    }
    
    // MARK: - 検索ロジック
    // iOS 15+ (現代的な書き方)
    private func performSearchAsync() async {
        // 1. 検索開始：状態のリセットとインジケーターの表示
        self.imageDatas = []
        self.showLoadingIndicator = true
        self.hasSearched = false // 検索開始時にリセット
        
        do {
            // 2. ImageLoaderのasync版を呼び出し、完了まで待機
            // エラーが発生した場合は直ちに catch ブロックへジャンプする
            try await imageLoader.search(searchText)
            // 3. 成功：取得した最新のリストを反映
            self.imageDatas = imageLoader.imageList
        } catch {
            // 4. 失敗：エラー内容を出力
            // try await で投げられたエラーをここで確実にキャッチする
            print("Search Error: \(error)")
        }
        
        // 5. 成功・失敗どちらでもインジケーターを止める
        // do-catchの外に書くことで、確実に実行される
        self.showLoadingIndicator = false
        self.hasSearched = true // 検索完了（成功・失敗問わず）
    }

    // iOS 15以前 (既存のロジック：クロージャ形式)
    private func performSearchLegacy() {
        // 1. 検索開始：状態のリセットとインジケーターの表示
        self.imageDatas = []
        self.showLoadingIndicator = true
        self.hasSearched = false // 検索開始時にリセット
        
        // 2. ImageLoaderのクロージャ版を呼び出す
        imageLoader.searchLegacy(searchText) { [weak self] result in
            // iOS 15以前 UI更新はメインスレッドで実行 
            DispatchQueue.main.async {
                guard let self = self else { return }
                // 3. Result型で成功と失敗を切り分ける
                switch result {
                case .success(let fetchedImages):
                    // 成功：取得した画像を反映
                    self.imageDatas = fetchedImages
                    
                case .failure(let error):
                    // 失敗：エラー内容を出力
                    print("Search Legacy Error: \(error)")
                }
                // 4. 成功・失敗どちらでもインジケーターを止める
                self.showLoadingIndicator = false
                self.hasSearched = true // 検索完了（成功・失敗問わず）
            }
        }
    }
}
