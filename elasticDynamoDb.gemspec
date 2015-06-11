$:.push File.expand_path("../lib", __FILE__)
$:.push File.expand_path("../lib/elasticDynamoDb", __FILE__)

require File.expand_path('../lib/elasticDynamoDb', __FILE__)

Gem::Specification.new do |s|
  s.name        = "elasticDynamoDb"
  s.version     = ElasticDynamoDb::VERSION
  s.authors     = ["Ami Mahloof"]
  s.email       = "ami.mahloof@gmail.com"
  s.homepage    = "https://github.com/innovia/ElasticDynamoDb"
  s.summary     = "scale dynamodb by factor with dynamic-dynamodb"
  s.description = "Elastically scale up or down with dynamic-dynamodb tool"
  s.required_rubygems_version = ">= 1.3.6"
  s.files = `git ls-files`.split($\).reject{|n| n =~ %r[png|gif\z]}.reject{|n| n =~ %r[^(test|spec|features)/]}
  s.add_runtime_dependency 'configparser', '~> 0'
  s.add_runtime_dependency 'thor', '~> 0.19', '>= 0.19.1'
  s.add_runtime_dependency 'aws-sdk', '~> 2.0.45', '>= 2.0.45'
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.extra_rdoc_files = ['README.md', 'LICENSE']
  s.license = 'MIT'
end
