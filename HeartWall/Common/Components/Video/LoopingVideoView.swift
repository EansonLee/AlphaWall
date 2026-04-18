//
//  LoopingVideoView.swift
//  HeartWall
//

import UIKit
import AVFoundation

final class LoopingVideoView: UIView {

    // MARK: - Properties

    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?

    private var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    // MARK: - Lifecycle

    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    deinit {
        tearDown()
    }

    // MARK: - Playback

    func configure(url: URL, isMuted: Bool = true, videoGravity: AVLayerVideoGravity = .resizeAspectFill) {
        tearDown()

        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.actionAtItemEnd = .none
        player.isMuted = isMuted
        playerLooper = AVPlayerLooper(player: player, templateItem: item)
        queuePlayer = player

        playerLayer.player = player
        playerLayer.videoGravity = videoGravity
        player.play()
    }

    func play() {
        queuePlayer?.play()
    }

    func pause() {
        queuePlayer?.pause()
    }

    private func tearDown() {
        queuePlayer?.pause()
        playerLayer.player = nil
        playerLooper = nil
        queuePlayer = nil
    }
}
