Pod::Spec.new do |s|

  s.name         = "MJPicHelper"
  s.version      = "0.0.1"
  s.summary      = "MJPicHelper--MJ-helper"

  #主页
  s.homepage     = "https://github.com/junwangInChina/MJPicHelper"
  #证书申明
  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  #作者
  s.author       = { "wangjun" => "github_work@163.com" }
  #支持版本
  s.platform     = :ios, "9.1"
  #版本地址
  s.source       = { :git => "https://github.com/junwangInChina/MJPicHelper", :tag => s.version }

  #库文件路径（相对于.podspec文件的路径）
  s.source_files  = "MJPicHelper/MJPicHelper/MJPicHelper/**/*.{h,m}"
  #是否支持arc
  s.requires_arc = true
  #外用库
  s.dependency 'Masonry'
  s.dependency 'AFNetworking'
  s.dependency 'SVProgressHUD'
  s.dependency 'SDWebImage'
  s.dependency 'JPush'
end