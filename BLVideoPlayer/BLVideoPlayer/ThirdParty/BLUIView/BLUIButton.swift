//
//  BLUIButton.swift
//  BLUIKit
//
//  Created by macos on 2023/2/20.
//

import UIKit

public class BLUIButton: UIButton {
    
    enum ButtonType: Int{
        case normalButton = 0
        case centerImgButton = 1
    }

    var imgSize: CGSize = .zero
    var type: ButtonType = .normalButton
    
    public var layoutBlock:((CGSize,UIButton)->Void)?
    
    public static func centerImgBtn(imgSize: CGSize) -> UIButton{
        let btn = BLUIButton()
        btn.layoutBlock = { s, b in
            let size = s
            b.imageView?.frame = .init(x: size.width/2.0-imgSize.width/2.0, y: size.height/2.0-imgSize.height/2.0, width: imgSize.width, height: imgSize.height)
        }
        return btn
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutBlock?(self.frame.size,self)
        
        return
        
        if self.type == .centerImgButton {
            if self.imgSize != .zero {
                let size = self.frame.size
                self.imageView?.frame = .init(x: size.width/2.0-imgSize.width/2.0, y: size.height/2.0-imgSize.height/2.0, width: imgSize.width, height: imgSize.height)
            }
        }
    }
}

