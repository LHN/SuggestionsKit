//
//  SuggestionsTextLayer.swift
//  Suggestions
//
//  Created by ilyailusha on 09.04.2020.
//  Copyright © 2020 ilyailusha. All rights reserved.
//

import Foundation
import UIKit


class SuggestionsTextLayer {

    var suggestionFrameClosue: ((SuggestionsManager.Suggestion) -> CGRect)?
    var textLayerUpdatedFrameClosue: ((CGRect) -> ())?
    
    private let config: SuggestionsConfig
    private var layer: CATextLayer = CATextLayer()
    
    init(parent: CALayer, config: SuggestionsConfig) {
        self.config = config
        commonInit(parent: parent, config: config)
    }
    
    func update(boundsForDrawing: CGRect, maxTextWidth: CGFloat, suggestion: SuggestionsManager.Suggestion, animationDuration: TimeInterval) {
        internalUpdate(boundsForDrawing: boundsForDrawing, maxTextWidth: maxTextWidth, suggestion: suggestion, animationDuration: animationDuration)
    }
}

private extension SuggestionsTextLayer {

    func internalUpdate(boundsForDrawing: CGRect, maxTextWidth: CGFloat, suggestion: SuggestionsManager.Suggestion, animationDuration: TimeInterval) {
        let attrs = [NSAttributedString.Key.font: config.text.font, NSAttributedString.Key.foregroundColor: config.text.textColor]
        let newString = NSAttributedString(string: suggestion.text, attributes: attrs)
        let newSize = newString.boundingRect(with: CGSize(width: maxTextWidth, height: CGFloat.greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size
        
        let suggFrame: CGRect = suggestionFrameClosue?(suggestion) ?? .zero
        
        let isRight = suggFrame.midX > boundsForDrawing.width / 2
        layer.bounds = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        layer.alignmentMode = isRight ? CATextLayerAlignmentMode.right : CATextLayerAlignmentMode.left
        
        
        let boundsToDraw: CGRect = boundsForDrawing
        var newFrame = CGRect(x: suggFrame.origin.x, y: suggFrame.origin.y - SuggestionsObject.Constant.spaceBetweenOverlayAndText, width: newSize.width, height: newSize.height)
        
        let shouldDrawBuble = config.buble.shouldDraw
        
        let yPositionAbove: CGFloat = {
            var original = suggFrame.minY - newSize.height - SuggestionsObject.Constant.spaceBetweenOverlayAndText
            if shouldDrawBuble {
                original -= SuggestionsObject.Constant.bubleOffset + config.buble.tailHeight + config.buble.focusOffset
            }
            
            return original
        }()
        let yPositionUnder: CGFloat = {
            var original = suggFrame.maxY + SuggestionsObject.Constant.spaceBetweenOverlayAndText
            if shouldDrawBuble {
                original += SuggestionsObject.Constant.bubleOffset + config.buble.tailHeight + config.buble.focusOffset
            }
            
            return original
        }()
        
        let xPosition: CGFloat = {
            if isRight {
                return max(boundsToDraw.maxX - newSize.width - SuggestionsObject.Constant.spaceBetweenOverlayAndText, boundsToDraw.minX)
            } else {
                return boundsToDraw.minX + SuggestionsObject.Constant.spaceBetweenOverlayAndText
            }
        }()
        
        if yPositionAbove < boundsToDraw.minY {
            newFrame.origin.y = yPositionUnder
        } else {
            newFrame.origin.y = yPositionAbove
        }
        newFrame.origin.x = xPosition
        
        let oldBounds = layer.bounds
        var newBounds = oldBounds
        newBounds.size = newFrame.size
        
        let opacityAnimation = CAKeyframeAnimation(keyPath:"opacity")
        opacityAnimation.values = [0,0,1,1,1]
        opacityAnimation.keyTimes = [0,0.001,0.99,0.999,1]

        
        let positionAnimation = CABasicAnimation(keyPath: "position")
        positionAnimation.fromValue = layer.value(forKey: "position")
        positionAnimation.toValue = NSValue(cgPoint: CGPoint(x: newFrame.midX, y: newFrame.midY))
        
        let boundsAnimation = CABasicAnimation(keyPath: "bounds")
        boundsAnimation.fromValue = NSValue(cgRect: oldBounds)
        boundsAnimation.toValue = NSValue(cgRect: newBounds)
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [positionAnimation, boundsAnimation, opacityAnimation]
        groupAnimation.fillMode = .forwards
        groupAnimation.duration = animationDuration
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        groupAnimation.isRemovedOnCompletion = true
        layer.frame = newFrame
        layer.string = newString
        textLayerUpdatedFrameClosue?(newFrame)
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.layer.removeAnimation(forKey: "bounds")
            self?.layer.removeAnimation(forKey: "position")
            self?.layer.removeAnimation(forKey: "contents")
            self?.layer.removeAnimation(forKey: "opacity")
        }
        layer.add(groupAnimation, forKey: "groupAnimation")
        CATransaction.commit()
    }
    
    func commonInit(parent: CALayer, config: SuggestionsConfig) {
        layer.contentsScale = UIScreen.main.scale
        layer.isWrapped = true
        layer.truncationMode = .none
        parent.addSublayer(self.layer)
    }
    
}
