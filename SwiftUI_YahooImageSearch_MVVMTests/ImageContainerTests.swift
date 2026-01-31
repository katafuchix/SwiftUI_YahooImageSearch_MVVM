//
//  ImageContainerTests.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import XCTest
@testable import SwiftUI_YahooImageSearch_MVVM // 自分のアプリ名

class ImageContainerTests: XCTestCase {

    var mockSession: URLSession!

        override func setUp() {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            mockSession = URLSession(configuration: config)
        }
    
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

    // 通信成功と保存成功のテスト
    func testLoadAndSaveSuccess() {
        let testURL = URL(string: "https://test.com/img.jpg")!
        
        // 保存処理をモック化（実際に保存せず、即座に完了セレクタを叩く）
        let saveSpy = { (image: UIImage, target: Any?, selector: Selector, context: UnsafeMutableRawPointer?) in
            let _ = (target as? NSObject)?.perform(selector, with: image, with: nil) // errorをnilで実行
        }
        
        let container = ImageContainer(from: testURL, session: mockSession, saveAction: saveSpy)
        
        // 1. Mockデータ準備
        let expectation = XCTestExpectation(description: "Async work")
        let testImageData = UIImage(systemName: "star")!.pngData()!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, testImageData)
        }
        
        // 2. Loadテスト
        container.load()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(container.isLoaded)
            
            // 3. Saveテスト
            container.saveToLibrary()
            XCTAssertTrue(container.showSaveAlert)
            XCTAssertEqual(container.alertMessage, "保存しました！")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}

// 通信を乗っ取るための共通クラス
class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    override class func canInit(with request: URLRequest) -> Bool { return true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { return request }
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else { return }
        do {
            let (response, data) = try handler(request)
            // this ではなく self に修正
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}
