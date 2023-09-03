//
//  BLVideoPlayerList.swift
//  BLVideoPlayerListDemo
//
//  Created by wkun on 2023/9/3.
//

import UIKit
import BLVideoPlayer

class BLVideoPlayerList: BLVideoPlayer,GKVideoScrollViewDataSource,GKVideoScrollViewDelegate {
    
    var datas: [VideoModel]?
    
    let scrollView = GKVideoScrollView.init(frame: UIScreen.main.bounds)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .black
        
        self.setupUI()
        
        self.loadDatas()
    }
    
    func loadDatas() {
        
        let mp4Url = "https://vd3.bdstatic.com/mda-phv1zugg2n3c8n4n/720p/h264/1693358819109409657/mda-phv1zugg2n3c8n4n.mp4?v_from_s=hkapp-haokan-hbe&auth_key=1693663538-0-0-533e7ed71380a893120cc0762bf2b3a0&bcevod_channel=searchbox_feed&cr=2&cd=0&pd=1&pt=3&logid=0338572677&vid=4140107770816422827&klogid=0338572677&abtest=112751_3"
        let u1 = "https://vdse.bdstatic.com/h265/bd33e0f8ecb635ff65f95502cb7981ddfa.mp4?cd=1&hit_bd265_src=1&mpd=1&pd=19&logid=11872197688304110566&vt=-1&svt=-1&cr_max=0&s_score=-1.000000&pt=1&av=15.6&vid=11242544689146001200&mvt=-1&did=d234bf90d0b895241d03e8a31f94f2c6&cr=0&h265_s=1&sl=161&sle=1&split=284878"
        let u2 = "https://vdse.bdstatic.com//c47beda17f019648b0e0b01f53939b66.mp4?authorization=bce-auth-v1%2F40f207e648424f47b2e3dfbb1014b1a5%2F2023-08-31T17%3A46%3A09Z%2F-1%2Fhost%2F62ffb09cbdc2542251bbbb43d52ce1cc3981ab8a2531dd015fe5979f6dd4c0bd"
        let nas = ["为什么相爱的人不能在一起","炫舞鹦鹉可爱爆棚","这叫声真好听"]
        let ulrs = [mp4Url,u1,u2]
        
        var arr = [VideoModel]()
        for i in 0..<10 {
            var cover = i%2 == 0 ? "c.jpg" : "c1.jpg"
            if i % 3 == 0 {
                cover = "c2.jpg"
            }
            let m = VideoModel()
            m.cover = cover
            m.url = ulrs[i%3]
            m.title = nas[i%3]
            arr.append(m)
        }
        self.datas = arr
        
        self.scrollView.reloadData()
    }
    
    // MARK: - ScrollViewDataSource
    // 内容总数
    func numberOfRows(in scrollView: GKVideoScrollView) -> Int {
        return self.datas?.count ?? 0
    }
    func scrollView(_ scrollView: GKVideoScrollView, cellForRowAt indexPath: IndexPath) -> GKVideoViewCell {
        let cell = scrollView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let c = cell as? VideoCell {
            c.model = self.datas?[indexPath.row]
        }
        return cell;
    }
    
    // MARK: - ScrollViewDelegate
    // 即将显示
    func scrollView(_ scrollView: GKVideoScrollView, willDisplay cell: GKVideoViewCell, forRowAt indexPath: IndexPath) {
        print("即将显示cell")
    }

    // 结束显示cell
    func scrollView(_ scrollView: GKVideoScrollView, didEndDisplaying cell: GKVideoViewCell, forRowAt indexPath: IndexPath) {
        self.stop(cell: cell as! VideoCell, index: indexPath.row)
    }

    // 滑动结束显示
    func scrollView(_ scrollView: GKVideoScrollView, didEndScrolling cell: GKVideoViewCell, forRowAt indexPath: IndexPath) {
        self.play(cell: cell as! VideoCell, index: indexPath.row)
    }
 
    // MARK: - SetupUI
    func setupUI() {
        self.scrollView.backgroundColor = .black
        scrollView.delegate = self
        scrollView.dataSource = self
        scrollView.register(VideoCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(self.scrollView)
    }
}

class VideoCell: GKVideoViewCell{
    let imgView = UIImageView()
    
    var model: VideoModel?{
        didSet{
            self.imgView.image = UIImage.init(named: model?.cover ?? "")
        }
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        imgView.contentMode = .scaleAspectFit
        self.addSubview(imgView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imgView.frame = self.bounds
    }
}

class VideoModel: NSObject{
    var title: String?
    var cover: String?
    var url: String?
}


// MARK: - 播放器

extension BLVideoPlayerList {
    
    func play(cell: VideoCell, index: Int) {
        
        guard let m = self.datas?[index] else {
            return
        }
        
        if let ul = URL.init(string: m.url ?? "") {
            let cimg = UIImage.init(named: m.cover ?? "")
            self.play(withURL: ul, videoTitle:m.title, containerView: cell.imgView, coverImg: cimg, needCheckSameUrl: true)
        }
    }
    
    func stop(cell: VideoCell, index: Int) {
        self.stop()
    }
}
