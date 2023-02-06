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

  opts.on("-s", "--list_categories", "Prints a list of valid categories") do
    TimeTracker::Track.list_categories
    exit
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

def generate_report
  beginning_of_year = Time.new(Time.new.year,01,01).strftime('%Y-%m-%d').to_s
  today = Time.new.strftime('%Y-%m-%d').to_s
  start_date, end_date, response = nil
  until start_date
    puts "Please provide a start date for your report, or leave blank for #{beginning_of_year}"
    print "Your response (YYYY-MM-DD) => "
    response = $stdin.gets.chomp
    start_date = response.empty? ? beginning_of_year : response
    unless valid_date?(start_date)
      puts "ERROR :: No valid date given."
      start_date, response = nil
    end
  end
  until end_date
    puts "Please provide an end date for your report, or leave blank for #{today}"
    print "Your response (YYYY-MM-DD) => "
    response = $stdin.gets.chomp
    end_date = response.empty? ? today : response
    unless valid_date?(end_date)
      puts "ERROR :: No valid date given."
      end_date, response = nil
    end
  end
  puts "\n\nCreating report starting #{start_date} through #{end_date}"
  r = TimeTracker::Report.new(start_date, end_date)
  puts "\n\n"
  puts r.generate_report_against_report_array_all_categories
end

def valid_date?(date_string)
  return true if Date.parse(date_string)
rescue ArgumentError
  return false
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
