source 'https://github.com/CocoaPods/Specs.git'

workspace 'Tesseract-OCR-iOS'
project 'TestsProject/TestsProject.xcodeproj/', 'Coverage' => :debug

use_frameworks!
platform :ios, '15.0'

target 'TestsProjectTests' do
	pod 'Kiwi'
end

post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
		config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
		end
	end
end
