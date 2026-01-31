//
//  ImageLoader.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import Foundation
import Combine

protocol ImageSearchProtocol {
    var imageList: [ImageData] { get }
    // iOS 15以降用
    func search(_ query: String) async throws
    // iOS 15未満用
    func searchLegacy(_ query: String, completion: @Sendable @escaping (Result<[ImageData], Error>) -> Void)
}

// 既存の ImageLoader を適合させる
extension ImageLoader: ImageSearchProtocol { }

// ネットワーク通信のルール
// 既存のメソッドと全く同じ形のルール（プロトコル）を定義して、URLSessionをそのルールに従わせる
protocol NetworkSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
    // @Sendable を追加してスレッド安全性を保証する
    func dataTask(with request: URLRequest, completionHandler: @Sendable @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

// URLSessionをこのルールに適合させる
extension URLSession: NetworkSessionProtocol {
}

@MainActor // クラス全体をメインアクターに隔離
class ImageLoader: ObservableObject {
    @Published var imageList: [ImageData] = []
    
    // 具体的な URLSession ではなく、プロトコルを持つ
    private let session: NetworkSessionProtocol

    // 初期値を URLSession.shared にすることで、アプリ実行時は今まで通り動く
    init(session: NetworkSessionProtocol = URLSession.shared) {
        self.session = session
    }

    nonisolated func parseHTML(_ html: String) -> [ImageData] {
        let pattern = "(https?)://msp.c.yimg.jp/([A-Z0-9a-z._%+-/]{2,1024}).jpg"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let results = regex.matches(in: html, options: [], range: NSRange(0..<html.count))
        
        return results.compactMap { result -> String? in
            let start = html.index(html.startIndex, offsetBy: result.range(at: 0).location)
            let end = html.index(start, offsetBy: result.range(at: 0).length)
            return String(html[start..<end])
        }
        .reduce([], { $0.contains($1) ? $0 : $0 + [$1] })
        .map { ImageData(url: URL(string: $0)!) }
    }

    @available(iOS 15.0, *)
    func search(_ keyword: String) async throws {
        let urlStr = "https://search.yahoo.co.jp/image/search?ei=UTF-8&p=\(keyword)"
        guard let encodedStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedStr) else {
            throw ImageError.noData
        }
        
        var request = URLRequest(url: url)
        request.addValue(Constants.mail, forHTTPHeaderField: "User-Agent")
        
        // sessionプロトコル経由で実行
        let (data, response) = try await session.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw ImageError.serverError
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw ImageError.noData
        }
        
        let fetchedImages = self.parseHTML(html)
        
        await MainActor.run {
            self.imageList = fetchedImages
        }
    }

    func searchLegacy(_ keyword: String, completion: @Sendable @escaping (Result<[ImageData], Error>) -> Void) {
        let urlStr = "https://search.yahoo.co.jp/image/search?ei=UTF-8&p=\(keyword)"
        guard let encodedStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedStr) else {
            completion(.failure(ImageError.noData))
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue(Constants.mail, forHTTPHeaderField: "User-Agent")
        
        // sessionプロトコル経由で実行
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                completion(.failure(ImageError.serverError))
                return
            }
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(ImageError.noData))
                return
            }
            let images = self.parseHTML(html)
            // クラス全体が @MainActor なので、imageList への代入は Task 内で行う
            Task { @MainActor in
                self.imageList = images
                completion(.success(images))
            }
        }.resume()
    }
}
