Pod::Spec.new do |spec|
  spec.name         = 'GCDHttpd'
  spec.version      = '3.1.0'
  spec.license      = { :type => 'Unknown' }
  spec.homepage     = 'https://github.com/aufflick/GCDHttpd'
  spec.authors      = { 'Robbie Hanson' => '' }
  spec.summary      = 'Simple GCD based Cocoa web server.'
  spec.source       = { :git => 'https://github.com/aufflick/GCDHttpd.git', :tag => 'v0.0.1' }
  spec.source_files = 'GCDHttpd/**/*.{h,m}'
  spec.frameworks   = 'Security', 'CFNetwork'
end
