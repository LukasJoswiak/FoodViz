# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

target 'FoodViz' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for FoodViz
  pod 'TesseractOCRiOS', '4.0.0'

  target 'FoodVizTests' do
    inherit! :search_paths
    # Pods for testing
  end

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_BITCODE'] = 'NO'
      end
    end
  end

end
