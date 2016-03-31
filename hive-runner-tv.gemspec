Gem::Specification.new do |s|
  s.name        = 'hive-runner-tv'
  s.version     = '0.1.2'
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = 'Hive Runner TV'
  s.description = 'The TV controller module for Hive Runner'
  s.authors     = ['Joe Haig']
  s.email       = 'joe.haig@bbc.co.uk'
  s.files       = Dir['README.md', 'lib/**/*.rb', 'js/**/*.js' ]
  s.homepage    = 'https://github.com/bbc-test/hive-runner-tv'
  s.license     = 'MIT'
  s.add_dependency 'hive-runner', '~> 2.0.11'
  s.add_dependency 'talkshow', '~> 1.4.1'
end
