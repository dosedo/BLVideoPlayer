//
//  BLVideoPlayer.swift
//  BLVideoPlayer
//
//  Created by wkun on 2023/9/2.
//

import UIKit
import ZFPlayer

open class BLVideoPlayer: UIViewController {
    
    let player = ZFPlayerController()
    let controlView = BLPlayerControlView.init(frame: UIScreen.main.bounds)
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
        self.setupPlayer()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.stop()
    }
    
    deinit{
        self.stop()
    }
    
    // MARK: - 播放与暂停
    public static func play(withURL url: URL, inCtrl: UIViewController) {
        let ctrl = BLVideoPlayer()
        ctrl.modalPresentationStyle = .overCurrentContext
        inCtrl.present(ctrl, animated: true) {
            ctrl.play(withURL: url)
        }
    }
    
    open func play(withURL url: URL, videoTitle: String? = nil, containerView: UIView? = nil, coverImg: UIImage? = nil, needCheckSameUrl: Bool = false) {
        let manager = player.currentPlayerManager
        
        if needCheckSameUrl {
            ///当前播放与要播放的内容一致，则忽略
            let playUrl = manager.assetURL?.absoluteString ?? ""
            if url.absoluteString == playUrl {
                return;
            }
        }
        
        let cv = containerView ?? self.view
        if player.containerView != cv {
            player.containerView = cv
        }
    
        if let cimg = coverImg {
            
            manager.view.coverImageView.contentMode = .scaleAspectFill
            manager.view.coverImageView.image = cimg
        }
        
        self.controlView.titleL.text = videoTitle
        self.player.assetURL = url;
    }
    
    open func stop() {
        self.player.stop()
    }
    
    // MARK: - 控制视图设置
    open func setEnableColumnAndBrightDrag(_ enable: Bool) {
        self.controlView.enableColumnAndBrightDrag = enable
    }
    
    // MARK: - 设置播放器
    func setupPlayer() {
        let manager = ZFAVPlayerManager()
        manager.shouldAutoPlay = true
        
        player.currentPlayerManager = manager
        player.disableGestureTypes = [.pan]
        player.allowOrentitaionRotation = false
    
        self.player.controlView = self.controlView
        
        weak var ws = self
        player.playerPlayStateChanged = { asset, state in
            guard let btn = ws?.controlView.playBtn else {
                return
            }
            if state == .playStatePlaying {
                btn.isSelected = true
            }else{
                btn.isSelected = false
            }
            
            if state == .playStatePlaying {
                if ws?.controlView.bgView.isHidden == false {
                    DispatchQueue.main.asyncAfter(deadline: .now()+2.0) {
                        ws?.controlView.bgView.isHidden = true
                    }
                }
            }
        }
        
        player.playerDidToEnd = { asset in
            ws?.player.currentPlayerManager.replay()
        }
        
        player.playerPlayTimeChanged = { asset, time, duration in
            
            //若正在拖动进度，则忽略
            if ws?.controlView.dragType == .progress {
                return;
            }
            
            if let progress = ws?.player.progress {
                ws?.controlView.sliderView.value = progress
            }
            
            ws?.controlView.timeView.currTimeL.text = time.toHourMinSecond()
            ws?.controlView.timeView.totalTimeL.text = duration.toHourMinSecond()
        }
    }
}

