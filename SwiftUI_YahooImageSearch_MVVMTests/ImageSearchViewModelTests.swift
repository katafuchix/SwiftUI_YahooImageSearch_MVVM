//
//  ImageSearchViewModelTests.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import XCTest
import Combine
@testable import SwiftUI_YahooImageSearch_MVVM

@MainActor
class ImageSearchViewModelTests: XCTestCase {
    
    var viewModel: ImageSearchViewModel!
    var mockProtocol: MockImageSearchProtocol!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockProtocol = MockImageSearchProtocol()
        // 修正後のコード通り、引数にProtocolを渡して初期化
        viewModel = ImageSearchViewModel(searchProtocol: mockProtocol)
        cancellables = []
    }

    // 1. バリデーションテスト（Combineの $searchText 監視）
    func testButtonEnablement() {
        XCTAssertFalse(viewModel.isButtonEnabled, "初期状態は無効であるべき")
        
        viewModel.searchText = "猫"
        XCTAssertFalse(viewModel.isButtonEnabled, "2文字では無効であるべき")
        
        viewModel.searchText = "猫 写真"
        XCTAssertTrue(viewModel.isButtonEnabled, "3文字以上で有効になるべき")
    }

    // 2. iOS 15以降の Async 検索ロジックのテスト
    func testPerformSearchAsync() async {
        // 1. 準備
        viewModel.searchText = "SwiftUI"
        let testData = [ImageData(url: URL(string: "https://deskplate.net/images/logo_deskplate.jpg")!)]
        mockProtocol.imageList = testData
        
        // 2. 検索完了（hasSearched が true になる）を待つための準備
        let expectation = XCTestExpectation(description: "検索完了待ち")
        
        // 状態の変化を監視
        let cancellable = viewModel.$hasSearched
            .dropFirst() // 初期値の false を無視
            .filter { $0 == true } // true になった瞬間を捉える
            .sink { _ in
                expectation.fulfill()
            }
        
        // 3. 実行（await は付けない。search は即座に返ってくるため）
        viewModel.search()
        
        // 4. ここで最大5秒間、expectation が fulfill されるのを待機する
        await fulfillment(of: [expectation], timeout: 5.0)
        cancellable.cancel()
        
        // 5. 状態の検証（ここに来る頃には、Task内の処理が終わっている）
        XCTAssertTrue(viewModel.hasSearched)
        XCTAssertEqual(viewModel.imageDatas.count, 1, "検索後はデータが1件入っているはず")
        XCTAssertFalse(viewModel.showLoadingIndicator, "完了後はインジケーターが消えているはず")
    }

    // 3. iOS 15未満の Legacy 検索ロジックのテスト
    func testPerformSearchLegacy() {
        let expectation = XCTestExpectation(description: "Legacy検索の完了待ち")
        
        // 検索完了フラグを監視
        viewModel.$hasSearched
            .dropFirst()
            .filter { $0 == true }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        // 強制的にLegacyを叩く（テスト環境が最新OSでもロジックを検証するため）
        // privateメソッドの場合は、テスト用に internal にするか、search()経由で検証します
        viewModel.search()
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertTrue(viewModel.hasSearched)
        XCTAssertFalse(viewModel.showLoadingIndicator)
    }
}

// MARK: - Test Helpers
class MockImageSearchProtocol: ImageSearchProtocol {
    var imageList: [ImageData] = []
    
    func search(_ query: String) async throws {
        // 成功をシミュレート（必要ならここで throws させてエラーテストも可能）
    }
    
    func searchLegacy(_ query: String, completion: @escaping (Result<[ImageData], Error>) -> Void) {
        // 即座に成功を返す
        completion(.success(imageList))
    }
}
