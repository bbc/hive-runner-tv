Gem::Specification.new do |s|
  s.name        = 'hive-runner-tv'
  s.version     = '0.0.1'
  s.date        = '2015-02-05'
  s.summary     = 'Hive Runner TV'
  s.description = 'The TV controller module for Hive Runner'
  s.authors     = ['Joe Haig']
  s.email       = 'joe.haig@bbc.co.uk'
  s.files       = Dir['README.md', 'lib/**/*.rb' ]
  s.homepage    = 'https://github.com/bbc-test/hive-runner-tv'
  s.license     = 'Apache2'
  s.add_runtime_dependency 'devicedb_comms'
end
