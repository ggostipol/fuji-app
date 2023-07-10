//
//  UIView.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 02.09.2020.
//

import UIKit

extension UIView {
    
    func pushTransition(_ duration: CFTimeInterval, _ from: CATransitionSubtype) {
        let animation:CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.push
        animation.subtype = from
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.push.rawValue)
    }
}
