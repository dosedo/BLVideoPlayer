//
//  BLLoadFrameworkImage.swift
//  BLVideoPlayer
//
//  Created by wkun on 2023/9/2.
//

import UIKit

extension NSObject{
    func image(cls: AnyClass?, name: String?) -> UIImage? {
        guard let cls = cls, let n = name else {
            return nil
        }
        
        return UIImage(named: n, in: Bundle(for: cls.self), compatibleWith: nil)
    }
    
    func image(_ name: String?) -> UIImage? {
        guard let n = name else {
            return nil
        }
        
        return UIImage(named: n, in: Bundle(for: type(of: self)), compatibleWith: nil)
    }
    
}
