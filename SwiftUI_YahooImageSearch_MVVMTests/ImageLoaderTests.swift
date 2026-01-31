//
//  ImageLoaderTests.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import XCTest
@testable import SwiftUI_YahooImageSearch_MVVM

@MainActor // テスト自体をメインアクターで実行
class ImageLoaderTests: XCTestCase {
    
    var mock: MockNetworkSession!
    var loader: ImageLoader!

    override func setUp() {
        super.setUp()
        mock = MockNetworkSession()
        loader = ImageLoader(session: mock)
    }

    func testParseHTML_ValidImages() {
        // 複数の画像URLが含まれるダミーHTML
        let dummyHTML = """
        <html>
            <body>
                <img src="https://msp.c.yimg.jp/yjimage/test1.jpg">
                <p>テキストが入っても大丈夫</p>
                <img src="https://msp.c.yimg.jp/yjimage/test2.jpg">
                <img src="https://msp.c.yimg.jp/yjimage/test1.jpg">
            </body>
        </html>
        """
        
        // 3. 実行：privateメソッドをテストしたい場合は、
        // プロジェクト設定で "Enable Testability" が Yes になっている必要があります。
        // （通常は ImageLoader 内の search を通じてテストするか、
        // parseHTML 自体を internal にしてテストします）
        
        // ここでは search を通さず、直接ロジックを確認する例です
        // ※ private のままだと呼べないので、テスト時は一時的に internal にするか
        // 下記のように search メソッドの挙動で確認します。
        
        let images = loader.parseHTML(dummyHTML) // internal 以上なら呼べる
        
        // 4. 検証
        XCTAssertEqual(images.count, 2, "重複を除いた2件が抽出されるはず")
        XCTAssertEqual(images[0].url.absoluteString, "https://msp.c.yimg.jp/yjimage/test1.jpg")
        XCTAssertEqual(images[1].url.absoluteString, "https://msp.c.yimg.jp/yjimage/test2.jpg")
    }

    func testParseHTML_NoImages() {
        let dummyHTML = "<html><body>画像がないHTML</body></html>"
        let images = loader.parseHTML(dummyHTML)
        
        XCTAssertTrue(images.isEmpty, "画像がない場合は空の配列が返るはず")
    }
    
    // 1. iOS 15+ Async版：正常系のテスト
    func testSearchAsyncSuccess() async throws {
        let dummyHTML = "<html><img src=\"https://msp.c.yimg.jp/success_async.jpg\"></html>"
        mock.dummyData = dummyHTML.data(using: .utf8)
        mock.dummyResponse = HTTPURLResponse(url: URL(string: "http://y.co")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        try await loader.search("test")
        
        XCTAssertEqual(loader.imageList.count, 1)
        XCTAssertEqual(loader.imageList.first?.url.absoluteString, "https://msp.c.yimg.jp/success_async.jpg")
    }

    // 2. iOS 15+ Async版：エラー系のテスト
    func testSearchAsyncServerError() async {
        // 500エラーをシミュレート
        mock.dummyResponse = HTTPURLResponse(url: URL(string: "http://y.co")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        mock.dummyData = Data()
        
        do {
            try await loader.search("test")
            XCTFail("サーバーエラー時はエラーが投げられるべき")
        } catch let error as ImageError {
            XCTAssertEqual(error, .serverError)
        } catch {
            XCTFail("想定外のエラー型です")
        }
    }

    // 3. iOS 15未満 Legacy版：正常系のテスト
    func testSearchLegacySuccess() {
        let dummyHTML = "<html><img src=\"https://msp.c.yimg.jp/success_legacy.jpg\"></html>"
        mock.dummyData = dummyHTML.data(using: .utf8)
        mock.dummyResponse = HTTPURLResponse(url: URL(string: "http://y.co")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let expectation = XCTestExpectation(description: "Legacy完了待ち")
        
        loader.searchLegacy("test") { result in
            if case .success(let images) = result {
                XCTAssertEqual(images.count, 1)
                
                Task { @MainActor in
                    let firstURL = images.first?.url.absoluteString
                    XCTAssertEqual(firstURL, "https://msp.c.yimg.jp/success_legacy.jpg")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }

    // 4. iOS 15未満 Legacy版：エラー系のテスト
    func testSearchLegacyNoData() {
        // HTML化できない不正なデータを返す
        mock.dummyData = nil
        mock.dummyResponse = HTTPURLResponse(url: URL(string: "http://y.co")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let expectation = XCTestExpectation(description: "Legacyエラー待ち")
        
        loader.searchLegacy("test") { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error as? ImageError, .noData)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}

class MockNetworkSession: NetworkSessionProtocol {
    var dummyData: Data?
    var dummyResponse: URLResponse?
    var dummyError: Error?

    // iOS 15+ 用
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = dummyError { throw error }
        return (dummyData ?? Data(), dummyResponse ?? URLResponse())
    }
    
    // iOS 15未満 / Legacy用
    func dataTask(with request: URLRequest, completionHandler: @Sendable @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        // 実際の通信はせず、偽の完了通知を即座に送るだけのTaskを返す
        return URLSession.shared.dataTask(with: URL(string: "about:blank")!) { _, _, _ in
            completionHandler(self.dummyData, self.dummyResponse, self.dummyError)
        }
    }
}
