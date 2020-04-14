//
//  UIViewControllerPreview.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 4/13/20.
//  Copyright © 2020 Chris Ballinger. All rights reserved.
//
//  https://gist.github.com/mattt/ff6b58af8576c798485b449269d43607

import UIKit

#if canImport(SwiftUI) && DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController
    
    init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }
    
    // MARK: - UIViewControllerRepresentable
    func makeUIViewController(context: Context) -> ViewController {
        viewController
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: UIViewControllerRepresentableContext<UIViewControllerPreview<ViewController>>) {
        return
    }
}

#endif
