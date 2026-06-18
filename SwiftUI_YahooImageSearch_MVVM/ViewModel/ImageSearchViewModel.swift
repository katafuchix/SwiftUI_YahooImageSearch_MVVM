//
//  ImageSearchViewModel.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import SwiftUI
import Observation

@MainActor // await から戻ってきた後の処理は自動的にメインスレッドで実行
@Observable
class ImageSearchViewModel {
    // Viewから参照する状態
    // Viewから参照する状態
    var searchText = "" {
        didSet {
            updateButtonEnabled()
            scheduleDebouncedSearch(oldValue: oldValue)
        }
    }
    var imageDatas = [ImageData]()
    var isLoading = false
    var showLoadingIndicator = false
    var isButtonEnabled = false
    var hasSearched = false // 一度でも検索を実行したか
    var selectedImageData: ImageData? = nil // これが非nilなら全画面表示
    var isShowingDetail = false // 全画面表示のフラグ
    
    private var debounceTask: Task<Void, Never>?
    private let searchProtocol: ImageSearchProtocol // 外から差し替え可能に
    
    init(searchProtocol: ImageSearchProtocol) {
        self.searchProtocol = searchProtocol
        updateButtonEnabled()
    }
    
    static func create() -> ImageSearchViewModel {
        return ImageSearchViewModel(searchProtocol: ImageLoader())
    }
    
    
    private func updateButtonEnabled() {
        isButtonEnabled = searchText.count >= 3
    }
    
    // Combineのdebounceの代わりにTaskで0.5秒待ってから検索する
    private func scheduleDebouncedSearch(oldValue: String) {
        // 同じ文字列の場合は何もしない
        guard oldValue != searchText else {
            return
        }
        
        // 前回の待機中タスクをキャンセルする
        debounceTask?.cancel()
        
        // 文字数が足りない場合は自動検索しない
        guard isButtonEnabled else {
            return
        }
        
        debounceTask = Task { [weak self] in
            // 0.5秒待つ
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // キャンセルされていたら検索しない
            guard !Task.isCancelled else {
                return
            }
            
            self?.search()
        }
    }
    
    
    func search() {
        debounceTask?.cancel()
        imageDatas = []
        UIApplication.shared.endEditing()
        
        Task {
            await performSearchAsync()
        }
    }
    
    // MARK: - 検索ロジック (iOS 15+)
    func performSearchAsync() async {
        self.imageDatas = []
        self.showLoadingIndicator = true
        self.hasSearched = false
        
        do {
            try await searchProtocol.search(searchText)
            self.imageDatas = searchProtocol.imageList
        } catch {
            print("Search Error: \(error)")
        }
        
        // do-catchの外に書くことで、確実に実行される
        self.showLoadingIndicator = false
        self.hasSearched = true
    }
}
