#!/usr/bin/env ruby
require 'date'
require 'optparse'
require_relative './lib/TimeTracker'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: timetrack.rb -c <category> -t <time> [description of work]"

  opts.on("-c <category>", "--category=<category>", "The category for this entry") do |c|
    options[:category] = c
  end

  opts.on("-t <time>", "--time=<time>", "Optional time for this entry as HH:MM:SS (defaults to now)") do |t|
    options[:time] = DateTime.strptime(t,'%T').to_time.strftime('%T')
  end

  opts.on("-e", "--eod", "Indicates the last entry of the current workday") do
    entry = TimeTracker::Track.generate_entry('eod', Time.new.strftime('%T'), 'END OF DAY')
    TimeTracker::Track.write_line_to_file(entry)
    exit
  end

  opts.on("-l", "--lunch", "Creates an entry for lunchtime") do
    entry = TimeTracker::Track.generate_entry('lunch', Time.new.strftime('%T'), 'LUNCH')
    TimeTracker::Track.write_line_to_file(entry)
    exit
  end

  opts.on("-r", "--report", "Prints a report grouped by category") do
    options[:report] = true
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

def generate_report
  puts "Please provide a start date for your report, or leave blank for 2018-01-01"
  print "Your response (YYYY-MM-DD) => "
  start_date = $stdin.gets.chomp
  start_date = '2018-01-01' unless is_date_this_year?(start_date)
  puts "Please provide an end date for your report, or leave blank for today"
  print "Your response (YYYY-MM-DD) => "
  end_date = $stdin.gets.chomp
  end_date = Time.new.strftime('%Y-%m-%d').to_s unless is_date_this_year?(end_date)
  puts "\n\nCreating report starting #{start_date} through #{end_date}"
  r = TimeTracker::Report.new(start_date, end_date)
  puts "\n\n"
  puts r.generate_report_against_report_array_all_categories
end

def is_date_this_year?(string)
  if string.empty?
    return false
  else
    t = string.split('-')
    if Time.new(t[0],t[1],t[2]) >= Time.new(2018,01,01)
      return true
    else
      return false
    end
  end
end

if options[:report]
  generate_report
  exit
end

category = TimeTracker::Track.set_valid_category(options[:category])
time = options[:time] || Time.new.strftime('%T')
description = TimeTracker::Track.set_valid_description(ARGV.join(' '))
entry = TimeTracker::Track.generate_entry(category, time, description)
TimeTracker::Track.write_line_to_file(entry)
