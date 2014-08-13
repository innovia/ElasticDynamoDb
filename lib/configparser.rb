class ConfigParser < Hash
  def initialize(fname = nil)
    @file_name = fname
  end

  def parse
    begin
      input_source = File.open(@file_name, "r").each_line if @file_name
    rescue Exception => e
      puts "error loading file -> #{e}"
    end
    config = {}
    config_section = nil

    input_source.each_with_index.inject(config) {|acc, (line, index)|
      if line =~ /^\[(.+?)\]/
        config_section = $1
        acc[config_section] ||= {}
      elsif line =~ /^(#|;|\n)/ && config_section  
          acc[config_section]["comment_#{index}"] = line
      elsif line =~ /^\s*(.+?)\s*[=:]\s*(.+)$/ && config_section # this returns a 2 parts $1 key, $2 value
          config_key   = $1
          config_value = $2
          acc[config_section][config_key] = config_value
      else
          acc['pre_section'] ||= {}
          acc['pre_section']["comment_#{index}"] = line
      end
      acc
    }
  end
end