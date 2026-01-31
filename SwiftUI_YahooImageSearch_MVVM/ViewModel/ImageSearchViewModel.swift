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
    @Published var hasSearched = false // 一度でも検索を実行したか
    @Published var selectedImageData: ImageData? = nil // これが非nilなら全画面表示
    @Published var isShowingDetail = false // 全画面表示のフラグ
    
    private var cancellables = Set<AnyCancellable>()
    private let searchProtocol: ImageSearchProtocol // 外から差し替え可能に
    
    init(searchProtocol: ImageSearchProtocol) {
        self.searchProtocol = searchProtocol
        
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
    
    static func create() -> ImageSearchViewModel {
        return ImageSearchViewModel(searchProtocol: ImageLoader())
    }
    
    func search() {
        self.imageDatas = []
        UIApplication.shared.endEditing()
        
        // ★OSバージョンによる分岐を復活
        if #available(iOS 15.0, *) {
            Task {
                await performSearchAsync()
            }
        } else {
            performSearchLegacy()
        }
    }
    
    // MARK: - 検索ロジック (iOS 15+)
    private func performSearchAsync() async {
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

    // MARK: - 検索ロジック (iOS 15以前)
    private func performSearchLegacy() {
        self.imageDatas = []
        self.showLoadingIndicator = true
        self.hasSearched = false
        
        searchProtocol.searchLegacy(searchText) { [weak self] result in
            // iOS 15以前 UI更新はメインスレッドで実行
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let fetchedImages):
                    self.imageDatas = fetchedImages
                case .failure(let error):
                    print("Search Legacy Error: \(error)")
                }
                self.showLoadingIndicator = false
                self.hasSearched = true
            }
        }
    }
}
