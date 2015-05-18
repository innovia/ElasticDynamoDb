#!/usr/bin/env ruby

module ElasticDynamoDb::Cli::CloudWatch
  
  def set_default_options(hash, member)
    if hash[member] && !hash[member].nil?
      default = hash[member]
    else
      default =  self.config["default_options"][member.to_s.gsub("_", "-")] if !self.config["default_options"][member.to_s.gsub("_", "-")].nil?
    end
  end

  def put_metric_alarm(table_options, mode, threshold, arn)
    cw_options = {
      alarm_name: "#{table_options[:table_name]}-#{mode.capitalize}CapacityUnitsLimit-BasicAlarm",
      alarm_description: "Consumed#{mode.capitalize}Capacity",
      actions_enabled: true,
      ok_actions: [arn],
      alarm_actions: [arn],
      metric_name: "Consumed#{mode.capitalize}CapacityUnits",
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
      threshold: threshold,
      evaluation_periods: 60,
      comparison_operator: "GreaterThanOrEqualToThreshold"
    }
    self.cw.put_metric_alarm(cw_options)
  end

  def set_cloudwatch_alarms(table_options)
    arn = set_default_options(table_options, :sns_topic_arn)   
    reads_upper_alarm_threshold = set_default_options(table_options, :reads_upper_alarm_threshold)      
    writes_upper_alarm_threshold = set_default_options(table_options, :writes_upper_alarm_threshold)

  	say  "Setting CloudWatch alarms thresholds for #{table_options[:table_name]} with upper read threshold of #{reads_upper_alarm_threshold}% and upper writes of #{writes_upper_alarm_threshold}%", color = :magenta
    
    if !arn.nil? && !reads_upper_alarm_threshold.nil? && !writes_upper_alarm_threshold.nil?
      put_metric_alarm(table_options, 'read', (table_options[:provisioned_throughput][:read_capacity_units] * 300) * reads_upper_alarm_threshold.to_i/100, arn)
      put_metric_alarm(table_options, 'writes', (table_options[:provisioned_throughput][:write_capacity_units] * 300) * writes_upper_alarm_threshold.to_i/100, arn)
  	else
      say "unable to find sns topic in config file - skipping cloudwatch alerts", color = :yellow
    end
  end
end