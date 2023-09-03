//
//  BLUITheme.swift
//  BLUIKit
//
//  Created by macos on 2023/2/20.
//

import UIKit

// MARK: - 颜色
public var Color082A74 = UIColor.hexColor(hex: "#082A74")
public var ColorBlue = UIColor.hexColor(hex: "#3478f7")
public var ColorMain = UIColor.hexColor(hex: "#293f66")
public let Color3 = UIColor.hexColor(hex: "333")
public let Color4 = UIColor.hexColor(hex: "444")
public let Color6 = UIColor.hexColor(hex: "666")
public let Color8 = UIColor.hexColor(hex: "888")
public let Color9 = UIColor.hexColor(hex: "999")
public let ColorC = UIColor.hexColor(hex: "CCC")
public let ColorA1 = UIColor.hexColor(hex: "A1A1A1")
public let ColorLine = UIColor.hexColor(hex: "E6EBF5")
public let ColorE5 = UIColor.hexColor(hex: "E5E5E5")
public let ColorEF = UIColor.hexColor(hex: "EFEFEF")
public let ColorF1 = UIColor.hexColor(hex: "F1F1F1")
public let ColorF6 = UIColor.hexColor(hex: "F6F6F6")
public let ColorFA = UIColor.hexColor(hex: "FAFAFA")
public let ColorF = UIColor.hexColor(hex: "FFF")
public let ColorRed = UIColor.hexColor(hex: "#f20202")
public let ColorBg = ColorF6
public let ColorF3F6FB = UIColor.hexColor(hex: "#f3f1f7")//"#F3F6FB")
public let ColorChartLine = UIColor.hexColor(hex: "#6AB4FF")

// MARK: - 对外使用
public func setupColorMain(colorMain: UIColor?) {
    if let c = colorMain {
        ColorMain = c
    }
}


// MARK: - Cupcake布局弹性字段
///Cupcake布局中的两端对齐
public let NERSpring = "<-->"

// MARK: - 常用尺寸
public let naviHeight   = UIViewController.naviViewHeight
public let tabbarHeight = UIViewController.tabHeight
public let screenWidth  = UIScreen.main.bounds.width
public let screenHeight = UIScreen.main.bounds.height
public let bottomSafeHeight = UIViewController.safeHeight

// MARK: - 字体
public let Font10 = Font(10)
public let Font11 = Font(11)
public let Font12 = Font(12)
public let Font13 = Font(13)
public let Font14 = Font(14)
public let Font15 = Font(15)
public let Font16 = Font(16)
public let Font17 = Font(17)
public let Font18 = Font(18)
public let Font20 = Font(20)
public let Font24 = Font(24)
public let Font28 = Font(28)

// MARK: - FontDigital
public func FontDigital(_ size: CGFloat) -> UIFont {
    return Font("Menlo-Bold,\(size)")
}

///SFUI-Bold
public func FontBold(_ size: CGFloat) -> UIFont {
    return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.bold)
}

public func FontHeitiLight(_ size: CGFloat) -> UIFont {
    return Font("STHeitiSC-Light,\(size)")
}

// MARK: - 类别
extension UIColor{
    @objc static func hexColor(hex: String?) -> UIColor {
        
        if hex == nil {return .black}

        if hex!.first == "#" {
            return Color(hex!) ?? .black
        }
        return Color("#"+hex!) ?? .black
    }
}

extension UIViewController {
    static var statusHeight: CGFloat{
       get{
           var h: CGFloat = 0.0
           if #available(iOS 13, *) {
               let height =
               UIApplication.shared.windows[0].windowScene?.statusBarManager?.statusBarFrame.height
               if let height = height {
                   h = height
               }
           }
           else{
               h = UIApplication.shared.statusBarFrame.height
           }
           return h
       }
    }
    
    static let naviViewHeight: CGFloat = UIViewController.statusHeight + 44.0
    static let tabHeight: CGFloat = (UIViewController.naviViewHeight > 64.0 ? 83.0: 49.0)
    static let safeHeight: CGFloat = UIViewController.tabHeight-49.0
}


class OCTheme: NSObject {
    // MARK: - 供OC调用的方法
    @objc static func getNaviHeight() -> CGFloat {
        return naviHeight
    }
    
    @objc static func colorMain() -> UIColor{
        return ColorMain
    }
    
    @objc static func color(hex:String?) -> UIColor?{
        return Color(hex)
    }
}




