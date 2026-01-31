//
//  ImageContainer.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import SwiftUI
import Combine
import UIKit

import UIKit
import SwiftUI

// ObservableObjectを継承したデータモデル
final class ImageContainer: NSObject, ObservableObject {
    // @PublishedをつけるとSwiftUIのViewへデータが更新されたことを通知してくれる
    @Published var image = UIImage(systemName: "photo")!
    @Published var isLoaded = false
    @Published var showSaveAlert = false // 通知表示フラグ
    @Published var alertMessage = ""      // 通知メッセージ
    private let url: URL

    // テストのために外部から注入可能にするプロパティ
    private let session: URLSession
    private let saveAction: (UIImage, Any?, Selector, UnsafeMutableRawPointer?) -> Void

    // イニシャライザ：テスト時には MockSession や MockSave を渡せる
    init(from url: URL,
         session: URLSession = .shared,
         saveAction: @escaping (UIImage, Any?, Selector, UnsafeMutableRawPointer?) -> Void = UIImageWriteToSavedPhotosAlbum) {
        self.url = url
        self.session = session
        self.saveAction = saveAction
        super.init()
    }

    func load() {
        guard !isLoaded else { return } // 二重ロード防止
        
        // 修正：共通の session プロパティを使用
        session.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let networkImage = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                // 宣言時に@Publishedを付けているので、プロパティを更新すればView側に更新が通知される
                self?.image = networkImage
                self?.isLoaded = true
            }
        }.resume()
    }
    
    // 保存実行メソッド
    func saveToLibrary() {
        guard !showSaveAlert else { return }
        
        // 修正：注入された saveAction を使用
        saveAction(image, self, #selector(saveError), nil)
    }

    @objc private func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            alertMessage = "保存に失敗しました: \(error.localizedDescription)"
        } else {
            alertMessage = "保存しました！"
        }
        withAnimation {
            showSaveAlert = true
        }
        
        // 2秒後に自動で消す
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                self.showSaveAlert = false
            }
        }
    }
}
/*
// ObservableObjectを継承したデータモデル
final class ImageContainer: NSObject, ObservableObject {
    // @PublishedをつけるとSwiftUIのViewへデータが更新されたことを通知してくれる
    @Published var image = UIImage(systemName: "photo")!
    @Published var isLoaded = false
    @Published var showSaveAlert = false // 通知表示フラグ
    @Published var alertMessage = ""      // 通知メッセージ
    private let url: URL

    init(from url: URL) {
        self.url = url
        super.init()
    }

    func load() {
        guard !isLoaded else { return } // 二重ロード防止
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let networkImage = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                // 宣言時に@Publishedを付けているので、プロパティを更新すればView側に更新が通知される
                self?.image = networkImage
                self?.isLoaded = true
            }
        }.resume()
    }
    
    // 保存実行メソッド
    func saveToLibrary() {
        // すでに通知が表示されている（＝保存中または表示中）なら何もしない
        guard !showSaveAlert else { return }
        
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
    }

    @objc private func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            alertMessage = "保存に失敗しました: \(error.localizedDescription)"
        } else {
            alertMessage = "保存しました！"
        }
        withAnimation {
            showSaveAlert = true
        }
        
        // 2秒後に自動で消す
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                self.showSaveAlert = false
            }
        }
    }
}
*/
