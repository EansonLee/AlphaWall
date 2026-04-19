//
//  LibraryViewModel.swift
//  HeartWall
//

import Combine
import CoreGraphics
import Foundation

final class LibraryViewModel: BaseViewModel {

    // MARK: - Inputs

    let viewDidLoad = PassthroughSubject<Void, Never>()

    // MARK: - Outputs

    @Published private(set) var featuredPages: [HeartQuotePage] = []
    @Published private(set) var sections: [HeartQuoteSection] = []

    // MARK: - Lifecycle

    override init() {
        super.init()
        bindInputs()
    }

    // MARK: - Binding

    private func bindInputs() {
        viewDidLoad
            .sink { [weak self] in
                self?.loadPages()
            }
            .store(in: &cancellables)
    }

    private func loadPages() {
        featuredPages = [
            HeartQuotePage(
                title: "罗盘指引着方向",
                assetName: "HeartQuotePagePrimary",
                cropRect: CGRect(x: 0.26, y: 0.02, width: 0.42, height: 0.48),
                subtitle: "每次点亮屏幕，希望都能为您明确内心的方向",
                badgeText: "内含13+张",
                tags: ["目标", "罗盘", "动态", "5.7w播放"]
            ),
            HeartQuotePage(
                title: "汲取向上生长的力量与精神共鸣",
                assetName: "HeartQuotePageSecondary",
                cropRect: CGRect(x: 0.00, y: 0.08, width: 1.00, height: 0.38),
                subtitle: "在光明、希望和生命力中，选择今天的能量",
                badgeText: nil,
                tags: ["光明", "希望", "生命力", "5.2w播放"]
            ),
            HeartQuotePage(
                title: "烟花赴新年",
                assetName: "HeartQuotePageTertiary",
                cropRect: CGRect(x: 0.00, y: 0.38, width: 1.00, height: 0.42),
                subtitle: "把新年愿望、光点和城市烟火收藏进屏幕",
                badgeText: nil,
                tags: ["新年", "烟花", "好运", "10张"]
            )
        ]

        sections = [
            HeartQuoteSection(
                title: "见者好运",
                countText: "含42张壁纸",
                items: [
                    HeartQuotePage(
                        title: "锦鲤莲花",
                        assetName: "HeartQuotePageSecondary",
                        cropRect: CGRect(x: 0.04, y: 0.22, width: 0.29, height: 0.39),
                        subtitle: "水面、锦鲤与莲花",
                        badgeText: nil,
                        tags: []
                    ),
                    HeartQuotePage(
                        title: "八方来财",
                        assetName: "HeartQuotePageSecondary",
                        cropRect: CGRect(x: 0.35, y: 0.22, width: 0.28, height: 0.39),
                        subtitle: "塔楼与夜空光束",
                        badgeText: nil,
                        tags: []
                    ),
                    HeartQuotePage(
                        title: "好运金鱼",
                        assetName: "HeartQuotePageSecondary",
                        cropRect: CGRect(x: 0.66, y: 0.22, width: 0.28, height: 0.39),
                        subtitle: "金鱼与暖色水光",
                        badgeText: nil,
                        tags: []
                    )
                ]
            ),
            HeartQuoteSection(
                title: "怀旧诺基亚",
                countText: "含12张壁纸",
                items: [
                    HeartQuotePage(
                        title: "N70回忆",
                        assetName: "HeartQuotePageSecondary",
                        cropRect: CGRect(x: 0.04, y: 0.73, width: 0.29, height: 0.27),
                        subtitle: "旧手机与握手画面",
                        badgeText: nil,
                        tags: []
                    ),
                    HeartQuotePage(
                        title: "功能表",
                        assetName: "HeartQuotePageSecondary",
                        cropRect: CGRect(x: 0.35, y: 0.73, width: 0.28, height: 0.27),
                        subtitle: "绿色屏幕旧时钟",
                        badgeText: nil,
                        tags: []
                    ),
                    HeartQuotePage(
                        title: "好好生活",
                        assetName: "HeartQuotePageSecondary",
                        cropRect: CGRect(x: 0.66, y: 0.73, width: 0.28, height: 0.27),
                        subtitle: "黑白按键与问候语",
                        badgeText: nil,
                        tags: []
                    )
                ]
            ),
            HeartQuoteSection(
                title: "每日心语",
                countText: "每日更新",
                items: [
                    HeartQuotePage(
                        title: "静坐片刻",
                        assetName: "HeartQuotePageTertiary",
                        cropRect: CGRect(x: 0.04, y: 0.00, width: 0.29, height: 0.29),
                        subtitle: "把心放回当下",
                        badgeText: nil,
                        tags: []
                    ),
                    HeartQuotePage(
                        title: "心灯不灭",
                        assetName: "HeartQuotePageTertiary",
                        cropRect: CGRect(x: 0.35, y: 0.00, width: 0.28, height: 0.29),
                        subtitle: "黑金佛像与光环",
                        badgeText: nil,
                        tags: []
                    ),
                    HeartQuotePage(
                        title: "一叶轻舟",
                        assetName: "HeartQuotePageTertiary",
                        cropRect: CGRect(x: 0.66, y: 0.00, width: 0.28, height: 0.29),
                        subtitle: "水墨留白与远山",
                        badgeText: nil,
                        tags: []
                    )
                ]
            )
        ]
    }
}
