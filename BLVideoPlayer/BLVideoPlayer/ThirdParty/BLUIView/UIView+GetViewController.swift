//
//  UIView+GetViewController.swift
//  MorninyDiaryB
//
//  Created by Met on 2021/4/3.
//  Copyright © 2021 bill. All rights reserved.
//

import UIKit

extension UIView{
    
    func currViewController() -> UIViewController? {
        return self.getViewController()
    }
    
    func getViewController()->UIViewController?{
        var next:UIView? = self
        repeat{
            if let nextResponder = next?.next{
                if(nextResponder.isKind(of: UIViewController.self)){
                    return (nextResponder as! UIViewController)
                }
            }
            next = next?.superview
        }while next != nil
        return nil
    }
}
