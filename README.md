## Elastic DynamoDb [![Gem Version](https://badge.fury.io/rb/elasticDynamoDb.svg)](http://badge.fury.io/rb/elasticDynamoDb)

  a wrapper tool to help with large planned traffic spike in combination with [dynamic-dynamodb](https://github.com/sebdah/dynamic-dynamodb)

  now supporting resetting CloudWatch alarms on table updates


[dynamic-dynamodb](https://github.com/sebdah/dynamic-dynamodb) tool is great for autoscaling but it has a few limitation:

* it does not accomodate for anticipated traffic spike that can last X hours

* it does not scale down at once to a certain value:
  becasue of the settings you gave it in the config file dynamic-dynamodb will decrease in percentages and you might get stuck with the AWS limit of no more than 4 decreases per 24 hours)


## Real example:

It's 10PM you know there's a planned marketing campaign of 4x the normal traffic that will start at 3AM and will last until 5AM 

You can launch elastic dynamodb as follow:

````bash
elasticDynamoDb --factor 4 \
                --config-file '../dynamic-dynamodb.conf' \
                --stop-cmd 'stop dynamic-dyanmodb' \ 
                --start-cmd 'start dynamic-dyanmodb' \
                --start-timer 300 \
                --schedule-restore 420
````

breakdown:

* factor
   <br />&nbsp;&nbsp;&nbsp;reads the current values off dyanmic-dynamodb.conf and scale the minimum for reads / writes by 4

* conifg-file <br />&nbsp;&nbsp;&nbsp; is the location for the dynamic-dynamodb.conf file

* stop-cmd <br />&nbsp;&nbsp;&nbsp;the command that will stop dynamic-dyanmodb process 

* start-cmd <br />&nbsp;&nbsp;&nbsp;the command that will start dynamic-dyanmodb process

* start-timer  <br />&nbsp;&nbsp;&nbsp;when to start the elasticDynamoDb operation (in 5 hours => 5 * 60 = 300 minutes)
* schedule-restore <br />&nbsp;&nbsp;&nbsp;when to restore back to the original values before this scale (in 7 hours => 7 * 60 = 420 minutes)

##Notes:

--factor 
can be decimal points for down scale - i.e 0.25 is 4x less the current values of the config file

--working-dir  
the process logs the changes to the tables in a folder called ElasticDynamoDB in your home folder, if you need to change that location for that folder use --working-dir

this is also the place where the config file is backed up to

--local
enable testing on [DynamoDbLocal] (http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tools.DynamoDBLocal.html#Tools.DynamoDBLocal.DownloadingAndRunning)

this changes the throuput of tables but:
>DynamoDB Local ignores provisioned throughput settings, even though the API requires them. For CreateTable, you can specify any numbers you want for provisioned read and write throughput, even though these numbers will not be used. You can call UpdateTable as many times as you like per day; however, any changes to provisioned throughput values are ignored.

--start-cmd / --stop-cmd [optional] stop and start dynamic-dyanmodb so that it doesn't intrrupt with the scale activity of ElasticDynamoDb

-- start-time / --schdeule-restore [optional] both or each separatly can be called
 

## Installation
    $ gem install elasticDynamoDb

````text
Usage: elasticDynamoDb

Commands:
  elasticDynamoDb                 # Ease autoscale by schedule or scale factor
  elasticDynamoDb version         # version

Options:
  --factor scale factor can be decimal too 0.5 for instance
  --config-file location of dynamic-dynamodb.conf
  --working-dir location for backup config and change log # Default: User home folder (~)
  
  --stop-cmd Bash stop command for dynamic-dynamodb service (must be wrapped in quotes)
  --start-cmd bash start command for dynamic-dynamodb service (must be wrapped in quotes)
              
  --start-timer   when to start the upscale automatically! value in minutes
  --schedule-restore number of minutes for ElasticDynamoDb to restore original values

  --local, [--no-local] # run on DynamoDBLocal
````

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License
ElasticDynamoDB is released under [MIT License](http://www.opensource.org/licenses/MIT)
