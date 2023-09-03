//
//  BLPlayerControlView.swift
//  VideoDemo
//
//  Created by wkun on 2023/9/1.
//

import UIKit
import MediaPlayer
import ZFPlayer
import Cupcake

enum BLPlayerControlDragType: Int{
    case notBegin = 0    //未开始
    case brightness = 1  //亮度
    case volumn = 2      //音量
    case progress = 3    //进度
}

class BLPlayerControlView: UIView, ZFPlayerMediaControl, UIGestureRecognizerDelegate{
    var player: ZFPlayerController?
    
    let backBtn = UIButton()
    let titleL = UILabel()
    let moreBtn = UIButton()
    let timeView = TimeView()
    let sliderView = BMTimeSlider()
    let rateBtn = UIButton()
    let fullscreenBtn = UIButton()
    let playBtn = BLUIButton()
    let bgView = BgView()
    
    var oldRate: Float = 1.0  //长按手势快进使用
    var dragType = BLPlayerControlDragType.notBegin
    var enableDrag = false    //是否开启拖动功能（除了底部进度）
    
    // 是否开启拖动调整音量和亮度（横屏时忽略）
    var enableColumnAndBrightDrag: Bool{
        set{
            self.enableColumnBrightDragGes = newValue
        }
        get{
            let isFullscreen = self.player?.isFullScreen ?? false
            return isFullscreen || enableColumnBrightDragGes
        }
    }
    private var enableColumnBrightDragGes = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        bgView.backgroundColor = .init(white: 0, alpha: 0.3)
        bgView.embedIn(self)
        bgView.isHidden = false
        
        ///顶部视图
        let bkimg = self.image("BMPlayer_back")
        backBtn.img(bkimg).pin(.wh(50, 50))
        titleL.font(14).color(ColorF)
        moreBtn.font(13).color(ColorF).str("更多")
        moreBtn.isHidden = true
        
        let topView = HStack(backBtn,10,titleL,NERSpring,moreBtn,10)
        topView.pin(.h(50.0)).addTo(bgView).makeCons { make in
            make.left.right.top.equal(0)
        }
        
        ///底部视图
        timeView.pin(.lowResistance)
        sliderView.maximumValue = 1.0
        sliderView.minimumValue = 0.0
        sliderView.setThumbImage(self.image("BMPlayer_slider_thumb"), for: .normal)
        sliderView.minimumTrackTintColor = .white
        sliderView.maximumTrackTintColor = .init(white: 0.5, alpha: 0.5)
        sliderView.pin(.h(50),.lowResistance)
//        sliderView.isUserInteractionEnabled = false
        sliderView.addTarget(self, action: #selector(handleSliderValueChange), for: .valueChanged)
        sliderView.addTarget(self, action: #selector(handleSliderEnd), for: .touchUpInside)
        sliderView.addTarget(self, action: #selector(handleSliderOutEnd), for: .touchUpOutside)
        sliderView.addTarget(self, action: #selector(handleSliderStart), for: .touchDown)
        
        rateBtn.pin(.wh(50, 45)).font(12).color(ColorF).str("倍速")
        
        fullscreenBtn.pin(.wh(50, 45)).img(self.image("BMPlayer_fullscreen"))
        let bottomView = HStack(10,timeView,10.0,sliderView,10.0,rateBtn,fullscreenBtn,10)
        bottomView.pin(.h(50)).addTo(bgView).makeCons { make in
            make.left.right.bottom.equal(0)
        }
        
        ///播放按钮
        playBtn.img(self.image("BMPlayer_play")).pin(.wh(55, 55)).addTo(bgView).makeCons { make in
            make.centerY.centerX.equal(bgView)
        }
        playBtn.setImage(self.image("BMPlayer_pause"), for: .selected)
        playBtn.layoutBlock = { size, btn in
            let w: CGFloat = 40.0
            btn.imageView?.frame = .init(x: size.width/2.0-w/2.0, y: size.height/2.0-w/2.0, width: w, height: w)
        }
        playBtn.imageView?.mode(.scaleAspectFill)
        playBtn.alpha = 0.5
        
        //事件
        fullscreenBtn.addTarget(self, action: #selector(handleFullBtn), for: .touchUpInside)
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        rateBtn.addTarget(self, action: #selector(handleRate), for: .touchUpInside)
        playBtn.addTarget(self, action: #selector(handlePlayBtn), for: .touchUpInside)
        
        
        self.addGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 手势
    func addGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tap)
        
        let longPress = UILongPressGestureRecognizer.init(target: self, action: #selector(handleLonePress))
        self.addGestureRecognizer(longPress)
        
        //音量、亮度、快进 滑动调整
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
    }
    
    @objc func handleTap() {
        self.bgView.isHidden = !self.bgView.isHidden
    }
    
    @objc func handleLonePress(_ ges: UIGestureRecognizer) {
        
        guard let manager = self.player?.currentPlayerManager as? ZFAVPlayerManager else {
            return
        }
        
        if ges.state == .began {
            self.oldRate = manager.player.rate
            manager.player.rate = 2.0
            let msg = "2.0倍速播放中"
            BLRateHUDView.shared.show(inView: self, text: msg, autoHide: false)
            
            ///倍速播放开始1秒后，隐藏控制视图
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                self.bgView.isHidden = true
            }
        }else if ges.state != .changed {
            manager.player.rate = self.oldRate
            BLRateHUDView.shared.hide()
        }
    }
    
    var beginLocation: CGPoint?
    var oldBrightness: CGFloat = 0.0
    var oldColumn: Float = AVAudioSession.sharedInstance().outputVolume
    var oldProgress: Float?
    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        if self.enableDrag == false {
            return
        }
        
        let translation = gestureRecognizer.translation(in: self)
        let location = gestureRecognizer.location(in: self)
        
        let size = self.frame
        
        switch gestureRecognizer.state {
        case .began:
            print("开始")
            beginLocation = location
            oldBrightness = UIScreen.main.brightness
            oldColumn = AVAudioSession.sharedInstance().outputVolume
            oldProgress = self.sliderView.value
        case .changed:
            
            print("ty=\(translation.y)")
            
            // 计算滑动的距离
            let horizontalDistance = abs(translation.x)
            let verticalDistance = abs(translation.y)
            
            // 根据触摸点的位置判断滑动方向和左右区域
            let isInLeftScreen = location.x < self.bounds.width / 2
            
            ///确定拖动的类型
            if self.dragType == .notBegin {
                //认定垂直滑动
                if verticalDistance > horizontalDistance && enableColumnAndBrightDrag {//&& (isUp || isDown) {
                    if isInLeftScreen {
                        dragType = .brightness
                        BLBrightnessProgressView.shared.show(inView: self, isVolumn: false, value: Float(UIScreen.main.brightness))
                    }else{
                        dragType = .volumn
                        let currentVolume = AVAudioSession.sharedInstance().outputVolume
                        BLBrightnessProgressView.shared.show(inView: self, isVolumn: true, value: Float(currentVolume))
                    }
                }else if verticalDistance < horizontalDistance {// && (isLeft || isRight) {
                    dragType = .progress
                    
                    BLDragProgressPreviewView.shared.show(inView: self)
                }
            }
            
            guard let beginLocation = beginLocation else {
                return
            }
            
            let dy = location.y-beginLocation.y
            let dx = location.x-beginLocation.x
            print("dy=\(dy)")
            
            if self.dragType == .brightness && enableColumnAndBrightDrag{
                
                let currentBrightness = oldBrightness//UIScreen.main.brightness
                let adjustedBrightness = currentBrightness - (dy / size.height * 2.0)
                UIScreen.main.brightness = max(0.0, min(1.0, adjustedBrightness))
                BLBrightnessProgressView.shared.setValue(Float(adjustedBrightness))
                
            }else if self.dragType == .volumn && enableColumnAndBrightDrag{
                // 右半边上下滑动，调整音量
                let currentVolume = oldColumn//AVAudioSession.sharedInstance().outputVolume
                let adjustedVolume = currentVolume - Float(dy / size.height * 2.0)
                self.setVolume(volume: adjustedVolume)
                BLBrightnessProgressView.shared.setValue(adjustedVolume)
            }
            else if self.dragType == .progress {
                //拖动快进快退
                guard let oldProgress = oldProgress else {
                    return
                }
                
                let adjustedProgress = oldProgress + Float(dx / size.width / 2.0)
                self.sliderView.value = max(0.0, min(1.0, adjustedProgress))
                if let totalTime = self.player?.currentPlayerManager.totalTime {
                    let toSec = totalTime*TimeInterval(sliderView.value)
                    self.timeView.currTimeL.text = toSec.toHourMinSecond()
                }
                
                BLDragProgressPreviewView.shared.updateValue(progress: CGFloat(sliderView.value), manager: self.player?.currentPlayerManager)
            }
            
        default:
            print("结束拖动")
            if dragType == .progress {
                if let totalTime = self.player?.currentPlayerManager.totalTime {
                    weak var ws = self
                    let toSec = totalTime*TimeInterval(sliderView.value)
                    self.player?.seek(toTime: toSec, completionHandler: { finished in
                        ws?.dragType = .notBegin
                    })
                }
            }else{
                self.dragType = .notBegin
            }

            BLBrightnessProgressView.shared.hide()
            beginLocation = nil
            oldProgress = nil
            BLDragProgressPreviewView.shared.hide()
            break
        }
    }

    // MARK: - 手势代理
    ///多手势冲突处理
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        ///只有当pan手势与uiscrollview的手势冲突时，才开启多手势处理
        var isNeedRecognized = false
        if gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) {
            if let gesCls = NSClassFromString("UIScrollViewPanGestureRecognizer"), let beginCls = NSClassFromString("UIScrollViewDelayedTouchesBeganGestureRecognizer") {
                if otherGestureRecognizer.isKind(of: gesCls) || otherGestureRecognizer.isKind(of: beginCls) {
                    isNeedRecognized = true
                }
            }
        }
        
        self.enableDrag = true
        if isNeedRecognized == false {
            return false
        }
        
        // 获取触摸点的位置
        let location = gestureRecognizer.location(in: self)
        
        let size = self.frame
        let w13 = size.width/3.0
        let w23 = size.width/3.0*2.0
        let y34 = size.height - 100.0//size.height/4.0*3.0
        // 判断触摸点是否在特定区域内
        if self.frame.contains(location) {
            
            ///若关闭了拖动调整音量和亮度，则在屏幕底部130pt以下拖动时响应进度调整、上部分则相应scrollview滑动
            ///只针对竖屏情况，横屏忽略
            if enableColumnAndBrightDrag == false {
                if location.y < (y34-20.0) {
                    self.enableDrag = false
                    return true
                }else{
                    self.enableDrag = true
                    return false
                }
            }
            
            // 在特定区域内，允许手势1和手势2同时触发.
            // 即当滑动屏幕中间位置时，禁用亮度、音量、进度的拖动、而触发scrollView的滚动
            if location.x > w13 && location.x < w23 && location.y < y34 {
                self.enableDrag = false
                return true
            }
        }
        
        self.enableDrag = true
        return false
    }
    
    // MARK: - 音量设置
    // 设置音量的函数
    var volumeView: MPVolumeView?
    func setVolume(volume: Float) {
        if volumeView == nil {
            let volumeView = MPVolumeView()
            // 添加音量视图，用于调整音量
            volumeView.frame = CGRect(x: -100, y: -100, width: 10, height: 10)
            self.addSubview(volumeView)
            
            self.volumeView = volumeView
        }
        let slider = volumeView?.subviews.first(where: { $0 is UISlider }) as? UISlider
        slider?.value = volume
    }
    
    class BgView: UIView {
        override var isHidden: Bool{
            didSet{
                super.isHidden = isHidden
                
                return;
                
                ///若播放中，则3秒后，自动隐藏控制视图
                if isHidden == false {
                    DispatchQueue.main.asyncAfter(deadline: .now()+3.0) {
                        if let sv = self.superview as? BLPlayerControlView {
                            if sv.player?.currentPlayerManager.isPlaying == true {
                                self.isHidden = true
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - TouchEvents
extension BLPlayerControlView {
    @objc func handleFullBtn() {
        print("点击全屏按钮")
        if let player = self.player {
            if player.isFullScreen {
                self.player?.enterFullScreen(false, animated: true)
            }else{
                self.player?.enterFullScreen(true, animated: true)
            }
        }
    }
    
    @objc func handleBack() {
        //全屏则退出全屏，否则返回上一页
        if let player = self.player, player.isFullScreen == true {
            player.enterFullScreen(false, animated: true)
        }else{
            print("退出视频")
            
            guard let ctrl = self.getViewController() else {
                return
            }
            
            if ctrl.navigationController != nil {
                ctrl.navigationController?.popViewController(animated: true)
            }else if ctrl.presentingViewController != nil {
                ctrl.dismiss(animated: true)
            }
        }
    }
    
    @objc func handleRate() {
        if let player = self.player {
            if let manager = player.currentPlayerManager as? ZFAVPlayerManager {
                let rate = manager.rate
                let isPlaying = manager.isPlaying
                
                self.bgView.isHidden = true
                BLSelectRateView.show(inView: self, isFullScreen: player.isFullScreen, currRate: CGFloat(rate)) { newRate in
                    if let r = newRate {
                        manager.rate = Float(r)
                        self.rateBtn.str("\(r)X")
                        if Float(r) != rate {
                            let msg = "已开启\(r)倍速播放"
                            BLRateHUDView.shared.show(inView: self, text: msg, autoHide: true)
                        }
                        
                        ///若设置倍速播放时，未播放视频，会自动开始播放，所以暂停下
                        if isPlaying == false {
                            manager.pause()
                        }
                    }else{
                        self.bgView.isHidden = false
                    }
                }
            }
        }
    }
    
    @objc func handlePlayBtn() {
        
        guard let manager = self.player?.currentPlayerManager as? ZFAVPlayerManager else {
            return
        }
        
        if manager.isPlaying {
            manager.pause()
        }else {
            manager.play()
        }
    }
    
    @objc func handleSliderStart() {
        
        print("开始滑动")
        
        self.dragType = .progress
        
        BLDragProgressPreviewView.shared.show(inView: self)
    }
    
    @objc func handleSliderEnd(){
        
        print("结束滑动")
        
        if let totalTime = self.player?.currentPlayerManager.totalTime {
            weak var ws = self
            let toSec = totalTime*TimeInterval(sliderView.value)
            self.player?.seek(toTime: toSec, completionHandler: { finished in
                ws?.handleSliderOutEnd()
            })
        }
    }
    
    @objc func handleSliderOutEnd() {
        
        print("截止滑动out")
        
        self.dragType = .notBegin
        
        BLDragProgressPreviewView.shared.hide()
    }
    
    @objc func handleSliderValueChange() {
        
        print("值变化\(sliderView.value)")
        
        if let totalTime = self.player?.currentPlayerManager.totalTime {
            let toSec = totalTime*TimeInterval(sliderView.value)
            self.timeView.currTimeL.text = toSec.toHourMinSecond()
        }
        
        BLDragProgressPreviewView.shared.updateValue(progress: CGFloat(sliderView.value), manager: self.player?.currentPlayerManager)
    }
}

// MARK: - Classes
///时间
class TimeView: UIView{
    let currTimeL = UILabel()
    let totalTimeL = UILabel()
    let midL = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        midL.color(ColorF).str("/")
        currTimeL.color(ColorF).str("00:00")
        totalTimeL.str("00:00")
        totalTimeL.textColor = .init(white: 1.0, alpha: 0.7)
        
        self.updateFontSize(size: 13)
        
        HStack(currTimeL,3.0,midL,3.0,totalTimeL).embedIn(self).align(.center)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateFontSize(size: CGFloat, isBold: Bool = false) {
        // 创建数字等宽字体
        let monospacedFont = UIFont.monospacedDigitSystemFont(ofSize: size, weight: .regular)
        totalTimeL.font = monospacedFont
        currTimeL.font = UIFont.monospacedDigitSystemFont(ofSize: size, weight: isBold ? .medium : .regular)
        midL.font = monospacedFont
    }
}

///进度滑块
class BMTimeSlider: UISlider {
    override open func trackRect(forBounds bounds: CGRect) -> CGRect {
        let trackHeight: CGFloat = 2
        let position = CGPoint(x: 0, y: 24)
        let customBounds = CGRect(origin: position, size: CGSize(width: bounds.size.width, height: trackHeight))
        super.trackRect(forBounds: customBounds)
        return customBounds
    }
    
    override open func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let rect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        let newx = rect.origin.x - 10
        let newRect = CGRect(x: newx, y: 0, width: 30, height: 50)
        return newRect
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let v = super.hitTest(point, with: event)
        
        print("hittext:\n\(v)")
        return v
    }
}

class BLRateHUDView: UIView{
    
    static let shared = BLRateHUDView()
    
    var text: String?{
        didSet{
            self.textL.text = text;
        }
    }
    private let textL = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        textL.font(12).color(ColorF)
        
        HStack(textL).embedIn(self,0,15)
        
        self.backgroundColor = .init(white: 0, alpha: 0.3)
        
        let h: CGFloat = 28.0
        self.pin(.h(h)).radius(h/2.0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(inView: UIView, text: String, autoHide: Bool) {
        self.text = text
        self.removeFromSuperview()
        self.addTo(inView).makeCons { make in
            make.centerX.equal(inView)
            make.top.equal(50)
        }
        
        if autoHide {
            DispatchQueue.main.asyncAfter(deadline: .now()+1.5) {
                self.hide()
            }
        }
    }
    
    func hide() {
        self.removeFromSuperview()
    }
}

///亮度和音量视图
class BLBrightnessProgressView: UIView {
    private let imgView = UIImageView()
    private let progressView = UIProgressView()
    
    static let shared = BLBrightnessProgressView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imgView.pin(.wh(16, 16)).mode(.scaleAspectFit)
        progressView.pin(.h(3.0),.lowResistance)
        progressView.trackTintColor = .init(white: 1.0, alpha: 0.5)
        progressView.tintColor = .white
        
        HStack(imgView,10,progressView).embedIn(self,0,15).align(.center)
        
        self.backgroundColor = .init(white: 0, alpha: 0.5)
        self.pin(.wh(210,30)).radius(15.0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setValue(_ value: Float) {
        self.progressView.progress = value
    }
    
    func show(inView: UIView, isVolumn:Bool, value: Float)  {
        let img = isVolumn ? "BL_volumn" : "BL_bright"
        self.imgView.image = self.image(img)
        
        self.progressView.progress = value
        
        self.removeFromSuperview()
        self.addTo(inView).makeCons { make in
            make.top.equal(60)
            make.centerX.equal(inView)
        }
    }
    
    func hide() {
        self.removeFromSuperview()
    }
}

///拖动时进度预览图片视图
class BLDragProgressPreviewView: UIView {
    let imgView = UIImageView()
    let timeView = TimeView()
    
    static let shared = BLDragProgressPreviewView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let w: CGFloat = 324.0/2.0
        let h: CGFloat = 184.0/2.0
        imgView.pin(.wh(w, h)).border(1.0, "#FFF").radius(5.0)
        imgView.backgroundColor = .black
        timeView.backgroundColor = .clear
        timeView.pin(.h(20))
        timeView.updateFontSize(size: 15, isBold: true)
        
        let tv = HStack(10,timeView,10).pin(.h(26)).radius(13.0).align(.center)
        tv.backgroundColor = .init(white: 0, alpha: 0.5)
        
        VStack(NERSpring,imgView,10,tv,10).embedIn(self).align(.center)
        
        self.backgroundColor = .clear
        self.pin(.wh(w,h+50))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(inView: UIView) {
        self.hide()
        self.addTo(inView).makeCons { make in
            make.centerX.equal(inView)
            make.bottom.equal(-60)
        }
    }
    
    func hide() {
        self.removeFromSuperview()
    }
    
    func updateValue(progress: CGFloat, manager:Any? ) {
//        self.player?.currentPlayerManager
        guard let manager = manager as? ZFAVPlayerManager else {
            return
        }
        
        //目标时间
        let toSecond = progress*manager.totalTime
        
        self.timeView.totalTimeL.text = manager.totalTime.toHourMinSecond()
        self.timeView.currTimeL.text = toSecond.toHourMinSecond()
        
        if let img = self.getVideoCurrentImage(second: toSecond, avAsset: manager.asset){
            self.imgView.image = img
        }
    }
    
    /// 获取视频的关键图片
    ///
    /// - Returns: 第几秒的图片
    func getVideoCurrentImage(second:Double, avAsset: AVURLAsset?) -> UIImage? {
//        var path: String? = ""
//        let avAsset = AVAsset(url: URL(fileURLWithPath: path!))
        guard let avAsset = avAsset else {
            return nil
        }
        let generator = AVAssetImageGenerator(asset: avAsset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTimeMakeWithSeconds(second, preferredTimescale: 600)
        var actualTime:CMTime = CMTimeMake(value: 0,timescale: 0)
        let imageRef:CGImage = try! generator.copyCGImage(at: time, actualTime: &actualTime)
        let currentImage = UIImage(cgImage: imageRef)
        
        return currentImage
    }
}

///倍速
class BLSelectRateView: UIView,UITableViewDataSource,UITableViewDelegate {
    let tableView = UITableView()
    
    var datas: [RateModel]?
    var handleBlock: ((CGFloat?)->Void)?
    var currRate: Float?
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let effectView = UIVisualEffectView.init(effect: UIBlurEffect(style: .dark))
        effectView.embedIn(self)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(RateCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 50
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        effectView.contentView.addSubview(self.tableView)
        
        self.backgroundColor = .init(white: 0, alpha: 0.1)
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        tableView.frame = self.bounds
    }
    
    // MARK: - Public
    static func show(inView: UIView, isFullScreen: Bool, currRate: CGFloat, handleBlock:@escaping (CGFloat?)->Void) {
        let fr = inView.bounds
        let bgView = UIButton()
        bgView.backgroundColor = .init(white: 0, alpha: 0.1)
        bgView.frame = fr
//        bgView.addTo(inView)
        
        guard let v = inView.getViewController()?.view else {
            return
        }
        //UIApplication.shared.keyWindow!
        bgView.addTo(v)
        
        let rateView = BLSelectRateView()
        let w: CGFloat = isFullScreen ? 120 : 100
        let h: CGFloat = isFullScreen ? fr.height-50.0 : 300.0
        rateView.pin(.wh(w, h)).addTo(bgView).makeCons { make in
            make.bottom.equal(-25)
            make.right.equal(-25)
        }
        rateView.radius(10.0)
        rateView.handleBlock = handleBlock
        rateView.loadDatas(selectedRate: currRate)
        bgView.addTarget(rateView, action: #selector(handleBgView), for: .touchUpInside)
        rateView.clipsToBounds = true
    }
    
    @objc func handleBgView() {
        self.handleBlock?(nil)
        self.hide()
    }
    
    func hide() {
        self.superview?.removeFromSuperview()
    }
    
    // MARK: - LoadDatas
    func loadDatas(selectedRate: CGFloat) {
        var ar = [RateModel]()
        let rates = [0.5,0.75,1.0,1.25,1.5,2.0]
        for r in rates.reversed() {
            let m = RateModel()
            m.rate = r
            m.rateText = "\(r)X"
            if r == 1.0 {
                m.rateText = "\(r)X (正常)"
            }
            m.isSelected = r == selectedRate
            ar.append(m)
        }
        self.datas = ar
        self.tableView.reloadData()
    }
    
    // MARK: - Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datas?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let c = self.datas?.count ?? 0
        if c > indexPath.row {
            (cell as? RateCell)?.model = datas?[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let datas = datas, datas.count > indexPath.row {
            self.handleBlock?(datas[indexPath.row].rate)
        }
        
        self.hide()
    }
    
    class RateCell: UITableViewCell {
        
        let rateL = UILabel()
        var model: RateModel?{
            didSet{
                rateL.text = model?.rateText
                if model?.isSelected == true {
                    rateL.color(ColorF).font("15")
                }else{
                    rateL.color(ColorF1).font(13)
                }
            }
        }
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            rateL.font(13).color(ColorF1).align(.center)
            
            let v = HStack(NERSpring,rateL,NERSpring).embedIn(contentView).align(.center)
            v.isUserInteractionEnabled = false
            
            self.selectionStyle = .none
            self.contentView.backgroundColor = .clear
            self.backgroundColor = .clear
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class RateModel: NSObject {
        var rate: CGFloat = 1.0
        var rateText: String?
        var isSelected = false
    }
}
