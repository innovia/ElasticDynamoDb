## Elastic DynamoDb [![Gem Version](https://badge.fury.io/rb/elasticDynamoDb.svg)](http://badge.fury.io/rb/elasticDynamoDb)

  an OnDemand tool to help with auto scaling of [dynamic-dynamodb](https://github.com/sebdah/dynamic-dynamodb)

[dynamic-dynamodb](https://github.com/sebdah/dynamic-dynamodb) tool is great for autoscaling but it has a few limitation:

* it does not scale down at once to a certain value

* it does not accomodate for anticipated traffic spike that can last X hours


ElasticDynamoDb is intended to extend the functionality of dynamic-dynamodb, allowing you to scale by a factor (up/down) and elastically return to the original values it had before

it's possible to automate the start and stop of the dynamic-dyanmodb service by passing a bash command (wrapped in quotes) to the --start_cmd / --stop_cmd options

## Installation
    $ gem install elasticDynamoDb

Usage:
````bash
  elasticDynamoDb onDemand \
    --config-file /etc/dynamic-dynamodb.conf \
    --factor 2 \
    --schedule-restore 120
    --start_cmd "sudo start dynamic-dynamodb" \
    --stop_cmd "sudo stop dynamic-dynamodb" 
````

````text
Options:
  --config-file = Location of dynamic-dynamodb.conf
  --factor = Scale factor can be decimal too 0.5 for instance
 [--schedule-restore = Number of minutes for ElasticDynamoDb to restore original values] # Default: 0 (No restore)
 [--working-dir = Location for backup config and change log [default current dir]]
 [--stop-cmd = Bash stop command for dynamic-dynamodb service] (must be wrapped in quotes)
 [--start-cmd = Bash start command for dynamic-dynamodb service] (must be wrapped in quotes)
````

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License
ElasticDynamoDB is released under [MIT License](http://www.opensource.org/licenses/MIT)
