$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "elasticDynamoDb"
  s.version     = ElasticDynamoDb::VERSION
  s.authors     = ["Ami Mahloof"]
  s.email       = "ami.mahloof@gmail.com"
  s.homepage    = "https://github.com/innovia/ElasticDynamoDb"
  s.summary     = "scale dynamodb by factor with dynamic-dynamodb"
  s.description = "Elastically scale up or down with dynamic-dynamodb tool"
  s.required_rubygems_version = ">= 1.3.6"
  s.files = ["lib/configparser.rb"]
  s.add_runtime_dependency 'configparser', '~> 0'
  s.add_runtime_dependency 'thor', '~> 0.19', '>= 0.19.1'
  s.add_runtime_dependency 'aws-sdk-core', '~> 2.0.17', '>= 2.0.17'
  s.executables = ["elasticDynamoDb"]
  s.extra_rdoc_files = ['README.md', 'LICENSE']
  s.license = 'MIT'
end
