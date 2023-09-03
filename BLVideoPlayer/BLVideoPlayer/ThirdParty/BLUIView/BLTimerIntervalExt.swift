//
//  BLTimerIntervalExt.swift
//  BLVideoPlayer
//
//  Created by wkun on 2023/9/2.
//

import Foundation


extension TimeInterval {
    
    func toHourMinSecond() -> String{
        let sec = Int(self)
        ///时分秒
        let s = sec%60
        let m = sec/60%60
        let h = sec/60/60
        var ti = String.init(format: "%02d:%02d", m,s)
        if h > 0 {
            ti = String.init(format: "%02d:\(ti)", h)
        }
        return ti
    }
}
