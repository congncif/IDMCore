#
# Be sure to run `pod lib lint IDMCore.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'IDMCore'
  s.version          = '2.3.0'
  s.summary          = 'Integrator - Data Provider - Model core architecture for data flow'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
IDM is short name of Integrator - Data Provider - Model. This is an additional support for MVC paradigm. It help you make clear data flow in iOS application. IDMCore contains core interfaces & base classes to build IDM flow.
                       DESC

  s.homepage         = 'https://github.com/congncif/IDMCore'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Nguyen Chi Cong' => 'congnc.if@gmail.com' }
  s.source           = { :git => 'https://github.com/congncif/IDMCore.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/congncif'

  s.ios.deployment_target = '8.0'

#.vendored_frameworks = 'IDMCore/*.framework'
s.source_files = 'IDMCore/Classes/*.swift'
  
  # s.resource_bundles = {
  #   'IDMCore' => ['IDMCore/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
s.frameworks = 'Foundation'
#s.dependency 'Result'
end
