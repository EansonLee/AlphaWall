platform :ios, '16.0'
use_frameworks!

target 'HeartWall' do
  # 布局
  pod 'SnapKit'

  # JSON 解析
  pod 'HandyJSON', :git => 'https://github.com/Miles-Matheson/HandyJSON.git'
  pod 'SwiftyJSON'

  # Swift 扩展工具库
  pod 'SwifterSwift'

  # 调试工具（仅 Debug）
  pod 'CocoaDebug', :configurations => ['Debug']
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
