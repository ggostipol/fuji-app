# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.5'
               end
          end
   end
end

target 'FujiVPN' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for FujiVPN
  pod 'GTProgressBar'
  pod 'DeviceLayout'
  pod 'Alamofire', '~> 5.2'
  pod 'Amplitude-iOS', '~> 4.9.3'
  pod 'ApphudSDK'
  pod 'SwiftMessages'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Messaging'
  pod 'Nuke'
  pod 'ReachabilitySwift'
  pod 'lottie-ios'
  pod 'SMIconLabel'
  pod 'BulletinBoard'
  pod 'JGProgressHUD'
  pod 'KeychainSwift', '~> 19.0'
  pod 'YandexMobileMetrica/Dynamic'
  pod 'APDAdColonyAdapter', '3.0.2.1'
  pod 'BidMachineAdColonyAdapter', '~> 2.0.0.0'
  pod 'APDAppLovinAdapter', '3.0.2.1'
  pod 'APDBidMachineAdapter', '3.0.2.1' # Required
  pod 'BidMachineAmazonAdapter', '~> 2.0.0.0'
  pod 'BidMachineCriteoAdapter', '~> 2.0.0.0'
  pod 'BidMachineSmaatoAdapter', '~> 2.0.0.0'
  pod 'BidMachineTapjoyAdapter', '~> 2.0.0.0'
  pod 'BidMachinePangleAdapter', '~> 2.0.0.0'
  pod 'BidMachineNotsyAdapter', '~> 2.0.0.4'
  pod 'APDGoogleAdMobAdapter', '3.0.2.1'
  pod 'APDIABAdapter', '3.0.2.1' # Required
  pod 'APDIronSourceAdapter', '3.0.2.1'
  pod 'APDStackAnalyticsAdapter', '3.0.2.1' # Required
  pod 'APDUnityAdapter', '3.0.2.1'
  pod 'APDVungleAdapter', '3.0.2.1'
  pod 'BidMachineVungleAdapter', '~> 2.0.0.1'
  
end
