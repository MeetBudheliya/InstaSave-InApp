//
//  SplashViewController.swift
//  share
//
//  Created by Meet's MAC on 19/05/22.
//

import UIKit
import AVFoundation

class SplashViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        //get video path from bundle
        guard let path = Bundle.main.path(forResource: "Splash", ofType:"mp4") else {
            debugPrint("splash.mp4 not found")

            let nextVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as! ViewController
            nextVC.modalTransitionStyle = .crossDissolve
            nextVC.modalPresentationStyle = .fullScreen
            self.navigationController?.present(nextVC, animated: true, completion: nil)
            return
        }

        // set video url in avplay and play splash video
        let videoURL = URL(fileURLWithPath: path)
        let player = AVPlayer(url: videoURL)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.containerView.bounds
        self.containerView.layer.addSublayer(playerLayer)
        player.play()
        player.rate = 1.6

        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            //navigate current vc to nextvc at video finish time
            DispatchQueue.main.asyncAfter(deadline: .now() + ((player.currentItem?.duration.seconds ?? 1) / 1.6) ) {
                let nextVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as! ViewController
                nextVC.modalTransitionStyle = .crossDissolve
                nextVC.modalPresentationStyle = .fullScreen
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        }
    }
}
