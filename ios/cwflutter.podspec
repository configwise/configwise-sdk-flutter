#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cwflutter.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cwflutter'
  s.version          = '1.0.11'
  s.summary          = 'ConfigWise SDK Flutter plugin'
  s.description      = <<-DESC
ConfigWise SDK Flutter plugin
                       DESC
  s.homepage         = 'https://github.com/configwise/configwise-sdk-flutter'
  s.license          = { :type => 'Apache-2.0', :file => '../LICENSE' }
  s.author           = { 'ConfigWise' => 'sdk@configwise.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'ConfigWiseSDK', '1.3.9'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
