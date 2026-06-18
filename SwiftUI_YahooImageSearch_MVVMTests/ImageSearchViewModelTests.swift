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
        
        /*
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
        */
        
        // 2. 実行：Taskを介さず、直接 await で完了を待つ
        // これなら待ち時間は「通信（モック）にかかる実時間」だけになります！
        await viewModel.performSearchAsync()
        
        // 5. 状態の検証（ここに来る頃には、Task内の処理が終わっている）
        XCTAssertTrue(viewModel.hasSearched)
        XCTAssertEqual(viewModel.imageDatas.count, 1, "検索後はデータが1件入っているはず")
        XCTAssertFalse(viewModel.showLoadingIndicator, "完了後はインジケーターが消えているはず")
    }
}

// MARK: - Test Helpers
class MockImageSearchProtocol: ImageSearchProtocol {
    var imageList: [ImageData] = []
    var errorToThrow: Error? // エラーテスト用
    
    func search(_ query: String) async throws {
        if let error = errorToThrow { throw error }
        // 本来はImageLoaderがimageListを更新する挙動をシミュレート
        // ViewModelがloader.imageListを見ているなら、ここで値をセットする
    }
    
    func searchLegacy(_ query: String, completion: @escaping (Result<[ImageData], Error>) -> Void) {
        // 即座に成功を返す
        if let error = errorToThrow {
            completion(.failure(error))
        } else {
            completion(.success(imageList))
        }
    }
}
