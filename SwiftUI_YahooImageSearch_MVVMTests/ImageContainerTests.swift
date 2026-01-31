//
//  ImageContainerTests.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import XCTest
@testable import SwiftUI_YahooImageSearch_MVVM // 自分のアプリ名

class ImageContainerTests: XCTestCase {

    func testImageLoading() {
        // 準備：テスト用のURL（実在する画像）
        let url = URL(string: "https://deskplate.net/images/logo_deskplate.jpg")!
        let container = ImageContainer(from: url)
        
        // 非同期処理を待つための「期待値（Expectation）」
        let expectation = XCTestExpectation(description: "画像をダウンロードする")
        
        // 実行
        container.load()
        
        // 監視：isLoadedがtrueになるまで最大5秒待つ
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if container.isLoaded {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // 検証
        XCTAssertTrue(container.isLoaded)
        XCTAssertNotEqual(container.image, UIImage(systemName: "photo"))
    }

}
