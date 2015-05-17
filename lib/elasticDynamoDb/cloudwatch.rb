#!/usr/bin/env ruby

module CloudWatch
	def method_name
		config['default_options'].keys.each { |k| puts k if k.match(/-alarm-/i) }  
	end

	def update_alarms(table_options)
		if table_options[:sns]
	      arn = table_options[:sns]
	    else
	      arn = config["default_options"]["sns-topic-arn"]
	    end
	    
	    if !arn.nil?

	      #if table_options.has_key?(:global_secondary_index_updates)
	     #   alarm_name = [""]
	          
	      ['READ', 'WRITE'].each {|mode|
	        cw_options = {
	          alarm_name: "#{table_options[:table_name]}-#{mode}CapacityUnitsLimit-BasicAlarm",
	          alarm_description: "Consumed#{mode}Capacity",
	          actions_enabled: true,
	          ok_actions: [arn],
	          alarm_actions: [arn],
	          metric_name: "Consumed#{mode}CapacityUnits",
	          namespace: "AWS/DynamoDB",
	          statistic: "Sum",
	          dimensions: [
	            {
	              name: "TableName",
	              value: table_options[:table_name]
	            }
	          ],
	          period: 60,
	          unit: "Count",
	          evaluation_periods: 1,
	          threshold: table_options[].to_i * 300,
	          comparison_operator: "GreaterThanOrEqualToThreshold"
	        }
	      }

	     # self.cw.put_metric_alarm(cloudwatch_options)
		else
	      say "unable to find sns topic in config file - skipping cloudwatch alerts", color = :yellow
	    end
	end
end