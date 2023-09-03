//
//  ViewController.swift
//  BLVideoPlayerListDemo
//
//  Created by wkun on 2023/9/3.
//

import UIKit
import BLVideoPlayer

class ViewController: UIViewController {
    
    @IBAction func handlePlayVideo(_ sender: Any) {
        let mp4Url = "https://vd3.bdstatic.com/mda-phv1zugg2n3c8n4n/720p/h264/1693358819109409657/mda-phv1zugg2n3c8n4n.mp4?v_from_s=hkapp-haokan-hbe&auth_key=1693663538-0-0-533e7ed71380a893120cc0762bf2b3a0&bcevod_channel=searchbox_feed&cr=2&cd=0&pd=1&pt=3&logid=0338572677&vid=4140107770816422827&klogid=0338572677&abtest=112751_3"
        guard let ul = URL.init(string: mp4Url) else { return }
        
        BLVideoPlayer.play(withURL: ul, inCtrl: self)
    }
    
    @IBAction func handlePlayList(_ sender: Any) {
        let playerList = BLVideoPlayerList()
        playerList.setEnableColumnAndBrightDrag(false)
        playerList.modalPresentationStyle = .fullScreen
        self.present(playerList, animated: true)
    }
}



