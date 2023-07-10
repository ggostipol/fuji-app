//
//  UIImage.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 15.08.2020.
//

import UIKit

extension UIImage {
    
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
