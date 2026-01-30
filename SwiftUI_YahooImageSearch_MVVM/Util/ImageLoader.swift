//
//  ImageLoader.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import Foundation
import Combine

class ImageLoader: ObservableObject  {
    
    @Published var imageList: [ImageData] = []
        
    // 1. パースロジックを共通化（ここでもエラーチェックが可能）
    private func parseHTML(_ html: String) -> [ImageData] {
        let pattern = "(https?)://msp.c.yimg.jp/([A-Z0-9a-z._%+-/]{2,1024}).jpg"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let results = regex.matches(in: html, options: [], range: NSRange(0..<html.count))
        
        return results.compactMap { result -> String? in
            let start = html.index(html.startIndex, offsetBy: result.range(at: 0).location)
            let end = html.index(start, offsetBy: result.range(at: 0).length)
            return String(html[start..<end])
        }
        .reduce([], { $0.contains($1) ? $0 : $0 + [$1] }) // ユニーク化
        .map { ImageData(url: URL(string: $0)!) }
    }

    // 2. iOS 15以降用：async/await 版
    @available(iOS 15.0, *)
    func search(_ keyword: String) async throws {
        let urlStr = "https://search.yahoo.co.jp/image/search?ei=UTF-8&p=\(keyword)"
        guard let encodedStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedStr) else {
            throw ImageError.noData
        }
        
        var request = URLRequest(url: url)
        request.addValue(Constants.mail, forHTTPHeaderField: "User-Agent")
        
        // 通信実行
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // ステータスコードチェック（元コードのガード条件）
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw ImageError.serverError
        }
        
        // HTMLデコードチェック（元コードのガード条件）
        guard let html = String(data: data, encoding: .utf8) else {
            throw ImageError.noData
        }
        
        // パース実行
        let fetchedImages = self.parseHTML(html)
        
        // メインスレッドで確実に反映（awaitで完了を待つ）
        await MainActor.run {
            self.imageList = fetchedImages
        }
    }

    // 3. iOS 15以前用：Completion Handler 版
    func searchLegacy(_ keyword: String, completion: @escaping (Result<[ImageData], Error>) -> Void) {
        let urlStr = "https://search.yahoo.co.jp/image/search?ei=UTF-8&p=\(keyword)"
        guard let encodedStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedStr) else {
            completion(.failure(ImageError.noData))
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue(Constants.mail, forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
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
            completion(.success(images))
        }.resume()
    }
}
