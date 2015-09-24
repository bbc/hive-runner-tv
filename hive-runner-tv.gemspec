Gem::Specification.new do |s|
  s.name        = 'hive-runner-tv'
  s.version     = '0.0.2'
  s.date        = '2015-02-05'
  s.summary     = 'Hive Runner TV'
  s.description = 'The TV controller module for Hive Runner'
  s.authors     = ['Joe Haig']
  s.email       = 'joe.haig@bbc.co.uk'
  s.files       = Dir['README.md', 'lib/**/*.rb' ]
  s.homepage    = 'https://github.com/bbc-test/hive-runner-tv'
  s.license     = 'MIT'
  s.add_dependency 'hive-runner', '~> 1.2.0'
end
