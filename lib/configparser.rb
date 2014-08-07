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
    section = nil
    key = nil

    input_source.inject(config) {|acc, line|
      acc ||= {}

      if line =~ /^\[(.+?)\]/ # if line contain section start adding it to a new hash key
        section = $1
        acc[section] ||= {}
      elsif line =~ /^(#|;|\n)/
        acc[section]["#{line}"] = line
      elsif line =~ /^\s*(.+?)\s*[=:]\s*(.+)$/ # this returns a 2 parts $1 first response, $2 2nd response
          key = $1
          value = $2
          acc[section] ||= {}
          acc[section][key] = value
      end

      acc
    }
  end
end