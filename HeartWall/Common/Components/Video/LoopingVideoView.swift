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
    private var requestedURL: URL?
    private var resolvedPlaybackURL: URL?
    private var configureTask: Task<Void, Never>?
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
        requestedURL = url
        playerLayer.videoGravity = videoGravity
        configureTask?.cancel()

        configureTask = Task { [weak self] in
            let playbackURL = url.isFileURL ? url : VideoCacheService.shared.playbackURL(for: url)
            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                guard let self, self.requestedURL == url else { return }

                if self.player == nil || self.resolvedPlaybackURL != playbackURL {
                    self.resetPlayer()

                    let item = AVPlayerItem(url: playbackURL)
                    let player = AVPlayer(playerItem: item)
                    player.actionAtItemEnd = .none
                    player.isMuted = isMuted

                    self.endObserver = NotificationCenter.default.addObserver(
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

                    self.player = player
                    self.playerLayer.player = player
                    self.resolvedPlaybackURL = playbackURL
                }

                self.player?.isMuted = isMuted
                self.playerLayer.videoGravity = videoGravity

                if self.shouldPlay, self.window != nil {
                    self.player?.play()
                }
            }
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

    private func resetPlayer() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil

        player?.pause()
        playerLayer.player = nil
        player = nil
        resolvedPlaybackURL = nil
    }

    private func tearDown() {
        configureTask?.cancel()
        configureTask = nil
        requestedURL = nil
        resetPlayer()
    }
}
