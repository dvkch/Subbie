inhibit_all_warnings!
use_frameworks!

target "Subtitler" do
    platform :osx, "10.13"
    pod 'SnapKit'
end

target "SubtitlerTests" do
    platform :osx, "10.13"
    pod 'Difference'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings.delete 'ARCHS'
        end
    end
end
