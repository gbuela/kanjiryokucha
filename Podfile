platform :ios, ‘9.3’

target 'KanjiRyokucha' do

  use_frameworks!

  # Pods for KanjiRyokucha
pod "ReactiveCocoa", :git => "https://github.com/ReactiveCocoa/ReactiveCocoa.git", :branch => ‘master’

pod 'Gloss', '~> 1.1'

pod 'UIColor_Hex_Swift', '~> 3.0.2'

pod 'PKHUD', '~> 4.0'

pod 'RealmSwift'

  target 'KanjiRyokuchaTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = ‘3.0’
    end
  end
end