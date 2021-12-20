platform :ios, ‘11.4’

# Pods for KanjiRyokucha
def shared_pods
    pod "ReactiveCocoa", '~> 10.2.0'
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
      config.build_settings['SWIFT_VERSION'] = ‘5.0’
    end
  end
end
