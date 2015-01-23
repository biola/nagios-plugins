#!/opt/chef/embedded/bin/ruby
require 'json'
require 'optparse'

# SMART attribute thresholds
thresholds = {
  # SMART 5 – Reallocated_Sector_Count
  '5' => {
    'warning' => 1,
    'critical' => 50
  },
  # SMART 187 – Reported_Uncorrectable_Errors
  '187' => {
    'warning' => 1,
    'critical' => 3
  },
  # SMART 188 – Command_Timeout
  '188' => {
    'warning' => 1,
    'critical' => 13000
  },
  # SMART 197 – Current_Pending_Sector_Count
  '197' => {
    'warning' => 1,
    'critical' => 2
  },
  # SMART 198 – Offline_Uncorrectable
  '198' => {
    'warning' => 1,
    'critical' => 2
  }
}

# Parse command line options
options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: check_smart.rb [options]\nThe check will monitor all detected hard drives by default"

  opts.on("-d", "--device DEVICE", "A physical disk to check, e.g. /dev/sda") do |d|
    options[:device] = d
  end

  opts.on("-i", "--interface TYPE", "The interface of the device, e.g. scsi") do |i|
    options[:interface] = i
  end

  opts.on("-r", "--regex REGEX", "A regular expression of disks to check, e.g. /dev/sd.{1,2}") do |r|
    options[:regex] = r
  end

  options[:verbose] = false
  opts.on("-v", "--verbose", "Return status of each hard drive") do |v|
    options[:verbose] = v
  end

  options[:extra_verbose] = false
  opts.on("-x", "--extra-verbose", "Return the status of each attribute of each hard drive") do |x|
    options[:extra_verbose] = x
  end

  options[:debug] = false
  opts.on("-z", "--debug", "Run in debugging mode") do |z|
    options[:debug] = z
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

# Use the specified device or scan for devices, optionally using a supplied regex as a filter
devices = Array.new
if options[:device]
  d = Hash.new
  d['device'] = options[:device]
  d['interface'] = options[:interface] || 'auto'
  devices << d
else
  `/usr/sbin/smartctl --scan`.each_line do |line|
    pieces = line.split(' ')
    d = Hash.new
    d['device'] = pieces[0]
    d['interface'] = options[:interface] || pieces[2]
    if options[:regex]
      devices << d if d['device'].match(/#{options[:regex]}/)
    else
      devices << d
    end
  end
end

if options[:debug]
  puts "Devices found:"
  puts devices.inspect
end

# Check the SMART attributes for each device
is_critical = false
is_warning = false
results = String.new

devices.each do |d|
  output = `sudo /usr/sbin/smartctl -A -d #{d['interface']} #{d['device']}`
  if options[:debug]
    puts "SMART attributes for #{d['interface']}:"
    puts output
  end
  output.each_line do |line|
    pieces = line.split(' ')
    thresholds.each do |attribute,t|
      if pieces[0] == attribute
        if pieces[9].to_i >= t['critical']
          is_critical = true
          results << "#{d['device']} attribute #{attribute} is CRITICAL; "
        elsif pieces[9].to_i >= t['warning']
          is_warning = true
          results << "#{d['device']} attribute #{attribute} is WARNING; "
        elsif options[:extra_verbose]
          results << "#{d['device']} attribute #{attribute} is OK; "
        end
      end
    end
  end

  if options[:verbose] && (results.empty? || !results.include?(d['device']))
    results << "#{d['device']} is OK; "
  end
end

# Return results
if is_critical
  puts "CRITICAL: #{results}"
  exit 2
elsif is_warning
  puts "WARNING: #{results}"
  exit 1
else
  if !results.empty?
    puts "OK: #{results}"
  else
    puts "OK: all disks passed"
  end
  exit 0
end
