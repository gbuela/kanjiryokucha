platform :ios, ‘9.3’

# Pods for KanjiRyokucha
def shared_pods
    pod "ReactiveCocoa", :git => "https://github.com/ReactiveCocoa/ReactiveCocoa.git", :branch => ‘master’
    pod 'Gloss', '~> 1.1'
    pod 'UIColor_Hex_Swift', '~> 3.0.2'
    pod 'PKHUD', '~> 4.0'
    pod 'RealmSwift'
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
      config.build_settings['SWIFT_VERSION'] = ‘3.0’
    end
  end
end
