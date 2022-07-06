//
//  SuggestionsHelper.swift
//  SuggestionsKit
//
//  Created by huemae on 05.05.2020.
//  Copyright (c) 2020 huemae <ilyailusha@hotmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import UIKit

public final class SuggestionsHelper {
    
    public enum SearchType {
        case byText(String)
        case byTag(Int)
        case classNameContains(String)
        case hitable
        case byaAcessibilityIdentifier(String)
    }
    
    public class SearchViewParameters: NSObject {
        let type: AnyObject.Type
        let search: SearchType
        
        public init(type: AnyObject.Type, search: SearchType) {
            self.type = type
            self.search = search
        }
    }
    
    public static func findViewRecursively(in view: UIView?, parameters: SearchViewParameters) -> UIView? {
        guard let mainView = view else { return nil }
        
        switch parameters.search {
        case .byTag(let tag):
            if mainView.tag == tag {
                return mainView
            }
            
        case .byText(let text) where parameters.type is UILabel.Type:
            if let label = mainView as? UILabel, label.text == text {
                return label
            }
            
        case .byText(let text) where parameters.type is UIButton.Type:
            if let button = mainView as? UIButton, button.titleLabel?.text == text {
                return button
            }
            
        case .byaAcessibilityIdentifier(let identifier):
            if mainView.accessibilityIdentifier == identifier {
                return mainView
            }
            
        case .classNameContains(let className):
            if String(NSStringFromClass(mainView.classForCoder)).contains(className) {
                return mainView
            }
            
        case .hitable:
            if mainView.hitTest(.zero, with: nil) == mainView {
                return mainView
            }
            
        default:
            break
        }
        
        return mainView.subviews.compactMap { findViewRecursively(in: $0, parameters: parameters) }.first
    }
    
    static public func findAllBarItems(in view: UIView?, captured: [UIView] = []) -> [UIView] {
        guard let mainView = view else { return captured }
        
        var newCaptured = Set(captured)
        
        for view in mainView.subviews {
            for finded in findAllBarItems(in: view, captured: Array(newCaptured)) where finded.isKind(of: UIControl.self) {
                newCaptured.insert(finded)
            }
            if view.isKind(of: UIControl.self) {
                newCaptured.insert(view)
            }
        }
        
        return Array(newCaptured)
            .filter { $0.isUserInteractionEnabled }
            .sorted(by: {
                guard let superFirst = $0.superview, let superSecond = $1.superview else { return true }
                let root = UIApplication.shared.keyWindow
                let leftX = superFirst.convert($0.frame, to: root).origin.x
                let rightX = superSecond.convert($1.frame, to: root).origin.x
                
                return leftX < rightX
            })
    }
}
