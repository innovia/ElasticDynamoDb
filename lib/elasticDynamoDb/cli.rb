#!/usr/bin/env ruby
require 'thor'
require 'aws-sdk-core'
require 'fileutils'

autoload :ConfigParser, 'elasticDynamoDb/configparser'

class ElasticDynamoDb::Cli < Thor
  include Thor::Actions
  default_task  :onDemand
  attr_accessor :restore_in_progress, :backup_folder, :config_file_name, :original_config_file, :config, :ddb,
                :log_file

  desc "onDemand", "Ease autoscale by schedule or scale factor"
  class_option :factor,            :type => :numeric,                         :banner => 'scale factor can be decimal too 0.5 for instance'
  class_option :config_file,                                                  :banner => 'location of dynamic-dynamodb.conf'
  class_option :working_dir,       :default => '~',                           :banner => 'location for backup config and change log [default home dir for the user]'
  class_option :stop_cmd,                                                     :banner => 'bash stop command for dynamic-dynamodb service' 
  class_option :start_cmd,                                                    :banner => 'bash start command for dynamic-dynamodb service'
  class_option :schedule_restore,  :type => :numeric, :default => 0,          :banner => 'number of minutes for ElasticDynamoDb to restore original values'
  class_option :timestamp,         :default => Time.now.utc.strftime("%m%d%Y-%H%M%S")
  class_option :local,             :type => :boolean, :default => false,      :desc => 'run on DynamoDBLocal'
  def onDemand
    raise Thor::RequiredArgumentMissingError, 'You must supply a scale factor' if options[:factor].nil?
    raise Thor::RequiredArgumentMissingError, 'You must supply the path to the dynamic-dyanmodb config file' if options[:config_file].nil?
    init
    aws_init

    process_config(options[:config_file], options[:factor])    
    
    if options[:schedule_restore] > 0 && !restore_in_progress
      say("#{Time.now} - Waiting here for #{options[:schedule_restore]} minutes until restore")
      sleep options[:schedule_restore] * 60
      
      self.restore_in_progress = true
      say "#{Time.now} - Restoring to original config file (#{self.original_config_file})"
      process_config(self.original_config_file, 1)
    end
      
    say "All done! you may restart the dynamic-dynamodb process", color = :white
  end

  map ["-v", "--version"] => :version
  desc "version", "version"
  def version
    say ElasticDynamoDb::ABOUT
  end

private
  def init
    working_dir = File.expand_path(options[:working_dir])
    self.config_file_name = File.basename(options[:config_file])
    read_config(File.expand_path(options[:config_file]))

    self.restore_in_progress = false

    self.backup_folder  = "#{working_dir}/ElasticDynamoDb/dynamodb_config_backups"
    self.log_file    = "#{working_dir}/ElasticDynamoDb/change.log" 

    self.original_config_file = "#{self.backup_folder}/#{self.config_file_name}-#{options[:timestamp]}"

    FileUtils.mkdir_p self.backup_folder
  end

  def aws_init
    if options[:local]
      ENV['AWS_REGION'] = 'us-east-1'
      say "using local DynamoDB"
      self.ddb = Aws::DynamoDB::Client.new({endpoint: 'http://localhost:4567', api: '2012-08-10'})
    else
      credentials = Aws::Credentials.new(
        self.config['global']['aws-access-key-id'], self.config['global']['aws-secret-access-key-id']
      )

      self.ddb = Aws::DynamoDB::Client.new({
        api: '2012-08-10', 
        region: self.config['global']['region'],
        credentials: credentials
      })  
    end
  end

  def process_config(file, factor)
    read_config(file)
    scale(factor)
    write_config(factor)
    begin
      if options[:stop_cmd]
        say "Stopping dynamic-dynamodb process using the command #{options[:stop_cmd]}"
        system(options[:stop_cmd])
      end 
    rescue Exception => e
      puts "error trying the stop command: #{e}"
    end
    update_aws_api
  end

  def read_config(config_file)
    self.config = ConfigParser.new(config_file).parse
  end

  def scale(factor=nil)
    if !factor.nil?
      scale_factor = factor

      active_throughputs = self.config.keys.select{|k| k =~ /table/}
      
      active_throughputs.each do |prefix|
        min_reads  = self.config[prefix]['min-provisioned-reads'].to_i
        min_writes = self.config[prefix]['min-provisioned-writes'].to_i

        say("(scale factor: #{scale_factor}) Global Secondary Index / Table: #{prefix.gsub('$','').gsub('^', '')} =>", color=:cyan)
        say("Current min-read from #{options[:config_file]}: #{min_reads}")
        say("Current min-write from #{options[:config_file]}: #{min_writes}")

        self.config[prefix]['min-provisioned-reads'] = (min_reads * scale_factor).to_i
        self.config[prefix]['min-provisioned-writes'] = (min_writes * scale_factor).to_i

        say("New min reads: #{self.config[prefix]['min-provisioned-reads']}", color=:yellow)
        say("New min writes: #{self.config[prefix]['min-provisioned-writes']}", color=:yellow)
        say("------------------------------------------------")
      end
    else
      say("Need a factor to scale by,(i.e scale --factor 2)", color=:green)
      exit
    end
  end

  def write_config(scale_factor)
    if options[:schedule_restore] > 0 
      restore = "\n\nAuto restore to backup config file (#{self.original_config_file}) in #{options[:schedule_restore]} minutes"
    else
      restore = "Backup will be save to #{self.original_config_file}"
    end

    if self.restore_in_progress
      confirmed = true
    else
      say "#{restore}", color = :white
      confirmed = yes?("Overwrite the new config file? (yes/no)", color=:white)
    end

    if confirmed
      backup
      
      str_to_write = ''
      self.config.each do |section, lines|
        if !section.include?('pre_section')
          str_to_write += "[#{section}]\n"
        end

        lines.each do |line, value|
          if value =~ /^(#|;|\n)/
            str_to_write += "#{value}"
          else
            str_to_write += "#{line}: #{value}\n"
          end
        end
      end
      
      save_file(str_to_write)

      if !self.restore_in_progress
        reason = ask("\nType the reason for the change: ", color=:magenta)
      else
        reason = "Auto restore to #{self.original_config_file}"
      end
      
      log_changes("#{reason} - Changed throughputs by factor of: #{scale_factor}")
      
      say("New config changes commited to file")
    else
      say("Not doing antything - Goodbye...", color=:green)
      exit
    end  
  end

  def log_changes(msg)
    say("Recording change in #{self.log_file}")

    File.open(self.log_file, 'a') do |file|
      file.write "#{Time.now} - #{msg}\n"
    end
  end

  def backup
    say "Backing up config file: #{self.original_config_file}"
    FileUtils.mkdir_p self.backup_folder
    FileUtils.cp options[:config_file], self.original_config_file 
  end

  def save_file(str)
    File.open(options[:config_file], 'w') do |file|
      file.write str
    end
  end

  def update_aws_api
    if self.restore_in_progress
      confirmed = true
    else
      confirmed = yes?("\nUpdate all tables with these values on DynamoDb? (yes/no)", color=:white)
    end

    if confirmed
     
      provisioning ={}

      active_throughputs = self.config.keys.select{|k| k =~ /table/}
      active_throughputs.inject(provisioning) { |acc, config_section|
        config_section =~ /^(gsi:\ *\^(?<index>.*)\$|)\ *table:\ *\^(?<table>.*)\$/
        index = $1
        table = $2
        
        if config_section.include?('gsi')
          acc[table] ||= {}
          acc[table][index] ||= {}
          acc[table][index]['reads']  = self.config[config_section]['min-provisioned-reads'].to_i
          acc[table][index]['writes'] = self.config[config_section]['min-provisioned-writes'].to_i
        else
          acc[table] ||= {}
          acc[table]['reads']  = self.config[config_section]['min-provisioned-reads'].to_i
          acc[table]['writes'] = self.config[config_section]['min-provisioned-writes'].to_i
        end
        acc  
      }
      log_changes("Update AWS via api call with the following data:\n #{provisioning}\n")
      say "\nWill update: #{provisioning.keys.size} tables\n\n\n", color = :blue
      update_tables(provisioning)
    else
      if self.restore_in_progress
        confirmed = true
      end

      if options[:start_cmd]
        confirmed = yes?("Send the start command #{options[:start_cmd]} ? (yes/no)")
      end

      if confirmed
        begin
          if options[:start_cmd]
            say "Starting up dynamic-dynamodb service using the command #{options[:start_cmd]}", color = :white
            system(options[:start_cmd])
          end 
        rescue Exception => e
          say "Error trying the start command: #{e.message}", color = :red
        end
      end
      exit
    end
  end

  def check_status(table_name)   
    until table_status(table_name) == 'ACTIVE' && !indexes_status(table_name).any? {|i| i != 'ACTIVE'}
      say("#{table_name} is not ACTIVE => sleeping for 30 sec and will retry again", color=:yellow)
      sleep 30
    end
    return true
  end

  def table_status(table_name)
    print "Checking table #{table_name} status..."
    status = self.ddb.describe_table({:table_name => table_name}).table.table_status 
    puts status
    status
  end

  def indexes_status(table_name)
    print "Checking indexes status on #{table_name}..."
    indexes_status = []
    if !self.ddb.describe_table({:table_name => table_name}).table.global_secondary_indexes.nil?
       self.ddb.describe_table({:table_name => table_name}).table.global_secondary_indexes.each {|i| indexes_status << i.index_status }
    end

    if indexes_status.empty?
      say("No indexes for #{table_name} table")
    else 
      say(indexes_status)
    end
    indexes_status
  end

  def update_single_table(table_options)
    while true
      ready = check_status(table_options[:table_name])

      if ready
        say "Updating provisioning for table: #{table_options[:table_name]}", color = :cyan
        begin
          result = self.ddb.update_table(table_options)
        rescue Exception => e
          say "\nUnable to update table: #{e.message}\n", color = :red
          
          if e.message.include?('The requested throughput value equals the current value')
            say "Skipping table update - the requested throughput value equals the current value", color = :yellow
            return         
          end

          dynamo_max_limit_error = 'Only 10 tables can be created, updated, or deleted simultaneously'
          if e.message.include?(dynamo_max_limit_error)
            say "#{dynamo_max_limit_error}\nTable #{table_options[:table_name]} is not ready for update, waiting 5 sec before retry", color = :yellow
            sleep 5          
          end

          say "\nRetrying update on #{table_options[:table_name]}", color = :yellow
          update_single_table(table_options) if e.message.include?('The requested throughput value equals the current value')          
        end
        return
        
      else
        say "Table #{table_options[:table_name]} is not ready for update, waiting 5 sec before retry", color = :yellow
        sleep 5
      end
    end  
  end

  def update_tables(provisioning)
    provisioning.each do |table, values|
      table_options = {
                  :table_name => table,
                  :provisioned_throughput => {
                                              :read_capacity_units =>  values['reads'],
                                              :write_capacity_units =>  values['writes']
                  }
      }
        
      # if one of the keys for the table contain index merge the options for update table
      indexes = provisioning[table].keys.select { |key| key.match(/index/) }
      if !indexes.empty?
        indexes.each do |index|
          table_options.merge!({ 
                         :global_secondary_index_updates => [{:update => { 
                                                                            :index_name => index,
                                                                            :provisioned_throughput => {
                                                                              :read_capacity_units =>  values[index]['reads'],
                                                                              :write_capacity_units => values[index]['writes'] 
                                                                            }
                                                                          }
                                                              }]
          })
        end
      end

      update_single_table(table_options)
    end
  end
end