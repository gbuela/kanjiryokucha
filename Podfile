platform :ios, ‘9.3’

# Pods for KanjiRyokucha
def shared_pods
    pod "ReactiveCocoa", '~> 9.0.0'
    pod 'UIColor_Hex_Swift', '~> 4.2.0'
    pod 'PKHUD', '~> 5.2.0'
    pod 'RealmSwift', '~> 3.17.1'
    pod 'SwiftRater', '~> 1.3.0'
    pod 'EasyTipView', '~> 2.0.4'
end

target 'KanjiRyokucha' do
    use_frameworks!
    shared_pods
end

target 'KanjiRyokucha-DEV' do
    use_frameworks!
    shared_pods
end


target 'KanjiRyokucha-Staging' do
    use_frameworks!
    shared_pods
end

target 'KanjiRyokuchaTests' do
    inherit! :search_paths
    # Pods for testing
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = ‘4.2’
    end
  end
end
