//
//  LoopingVideoView.swift
//  HeartWall
//

import UIKit
import AVFoundation

final class LoopingVideoView: UIView {

    // MARK: - Properties

    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var configuredURL: URL?
    private var shouldPlay = false

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

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard player != nil else { return }

        if window == nil {
            player?.pause()
        } else if shouldPlay {
            player?.play()
        }
    }

    // MARK: - Playback

    func configure(url: URL, isMuted: Bool = true, videoGravity: AVLayerVideoGravity = .resizeAspectFill) {
        if configuredURL != url || player == nil {
            tearDown()

            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            player.actionAtItemEnd = .none
            player.isMuted = isMuted

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.player?.seek(to: .zero)
                if self.shouldPlay {
                    self.player?.play()
                }
            }

            configuredURL = url
            self.player = player
            playerLayer.player = player
        }

        player?.isMuted = isMuted
        playerLayer.videoGravity = videoGravity

        if shouldPlay {
            player?.play()
        }
    }

    func play() {
        shouldPlay = true
        player?.play()
    }

    func pause() {
        shouldPlay = false
        player?.pause()
    }

    private func tearDown() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil

        player?.pause()
        playerLayer.player = nil
        player = nil
        configuredURL = nil
    }
}
