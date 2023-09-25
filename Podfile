# Uncomment this line to define a global platform for your project
platform :ios, "15.0"
use_frameworks!

# Ignore all warnings from pods.
inhibit_all_warnings!

source 'https://github.com/CocoaPods/Specs.git'

target "SudoApiClient" do
  podspec :name => 'SudoApiClient'
end

target "SudoApiClientTests" do
  podspec :name => 'SudoApiClient'
end

target "SudoApiClientIntegrationTests" do
  podspec :name => 'SudoApiClient'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED'] = 'YES'
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end
