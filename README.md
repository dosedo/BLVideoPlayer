# BLVideoPlayer

BLVideoPlayer is a Swift-based video player implemented with features 
such as brightness adjustment, volume control, drag-to-seek, landscape and portrait mode switching, 
and vertical swipe for video switching when in portrait mode. The code is encapsulated within a framework for easy integration.

BLVideoPlayer是一款swift实现的、具有亮度调节、音量调节、拖动快进、横竖屏切换以及竖屏时上下滑动切换视频的功能，代码封装在framework中，方便调用

# How to use it?

```
//import framework
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
```
Please refer to the demo code
请参考demo代码
