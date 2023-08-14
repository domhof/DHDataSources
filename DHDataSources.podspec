Pod::Spec.new do |s|
  s.name             = 'DHDataSources'
  s.version          = '0.1.1'
  s.summary          = 'IndexPath based datasources and adapters providing data for UITableView and UICollectionView.'

  s.description      = <<-DESC
IndexPath based datasources and adapters providing data for UITableView and UICollectionView.
                       DESC

  s.homepage         = 'https://github.com/domhof/DHDataSources'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Dominik Hofer' => 'me@dominikhofer.com' }
  s.source           = { :git => 'https://github.com/domhof/DHDataSources.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/dominikhofer'

  s.ios.deployment_target = '11.0'

  s.source_files = 'DHDataSources/Classes/**/*.swift'
end
