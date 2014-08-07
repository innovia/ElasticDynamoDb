# Elastic DynamoDb - an OnDemand tool to help with auto scaling of dynamic-dynamodb

 [dynamic-dynamodb](https://github.com/sebdah/dynamic-dynamodb) tool is great for autoscaling, however it does not scale down at once to certian value
  and it does not accomodate for anticipated traffic spike that can last X hours

  This tool is intended to extend the functionality of dynamic-dynamodb, allowing you to scale by a factor (up/down) and elastically return to the original values it had before

  it possible to automate the start and stop of the service by passing a bash command to the --start_cmd / --stop_cmd

## Installation

    $ gem install elasticDynamoDb

Usage:
  elasticDynamoDb onDemand --config-file=location of dynamic-dynamodb.conf --factor=Scale factor (can be decimal too, i.e: 0.5) --schedule-restore 120

Options:
  --config-file=location of dynamic-dynamodb.conf
  --factor scale factor can be decimal too 0.5 for instance
  [--schedule-restore=number of minutes for ElasticDynamoDb to restore original values] # Default: 0 (No restore)
  [--working-dir=location for backup config and change log [default current dir]]
  [--stop-cmd=bash stop command for dynamic-dynamodb service]
  [--start-cmd=bash start command for dynamic-dynamodb service]

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License
ElasticDynamoDB is released under [MIT License](http://www.opensource.org/licenses/MIT)