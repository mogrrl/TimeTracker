require 'yaml'
module TimeTracker

  BASEDIR = File.dirname(File.expand_path('..', __FILE__)) # parent directory of this file
  TRACKER_FILE = BASEDIR + '/tracker.txt'

  CONFIG = YAML.load_file(BASEDIR + '/lib/config.yml')

  CATEGORIES = CONFIG['categories'] + [ 'none' ] # reserved - do not delete or alter

  class Track
    class << self
      def generate_entry(category, start_time, description)
        case
        when category == 'eod'
          entry = "#{Time.new.strftime('%Y-%m-%d')} #{start_time} :: none :: END OF DAY\n\n\n"
        when category == 'lunch'
          entry = "#{Time.new.strftime('%Y-%m-%d')} #{start_time} :: none :: LUNCH"
        else
          entry = "#{Time.new.strftime('%Y-%m-%d')} #{start_time} :: #{category} :: #{description}"
        end
        return entry
      end

      def write_line_to_file(string)
        f = File.open(TimeTracker::TRACKER_FILE, 'a+')
        f.write(string + "\n")
        f.close
        puts string
      end

      def is_category?(string)
        case
        when string.nil?
          return false
        when TimeTracker::CATEGORIES.grep(/^#{string}/i)[0]
          return true
        else
          return false
        end
      end

      def description_present?(string)
        case
        when string.empty?
          return false
        when string =~ /^ *$/ # regexp returns true if string consists of spaces only
          return false
        else
          return true
        end
      end

      def set_valid_category(string)
        until is_category?(string)
          string = get_input_from_stdin('category')
        end
        return TimeTracker::CATEGORIES.grep(/^#{string}/i)[0]
      end

      def set_valid_description(string)
        until description_present?(string)
          string = get_input_from_stdin('description')
        end
        return string
      end

      def get_input_from_stdin(type)
        puts # start with whitespace
        case
        when type == 'category'
          puts "You did not provide a valid category.  Please choose a category from:\n  #{TimeTracker::CATEGORIES.join("\n  ")}"
        when type == 'description'
          puts "Please provide a non-empty string that describes your work for this entry."
        end
        print "Your response => "
        return $stdin.gets.chomp
      end
    end
  end

  class Report
    @@entries = []
    attr_accessor :start_date, :end_date, :report_array
    def initialize(start_date, end_date)
      @@entries << self.parse_file
      @start_date = Time.new(start_date.split('-')[0],start_date.split('-')[1],start_date.split('-')[2])
      @end_date = Time.new(end_date.split('-')[0],end_date.split('-')[1],end_date.split('-')[2])
      @report_array = self.get_report_array
    end

    def generate_report_against_report_array_all_categories
      a = []
      # grand total
      total_seconds = seconds = self.report_array.map{|i| i[:duration]}.compact.reduce(0, :+)
      a << "Total time worked #{@start_date.strftime("%Y-%m-%d")} to #{@end_date.strftime("%Y-%m-%d")}: #{seconds_to_hms(total_seconds)} (HH:MM:SS)\n\n"
      # category totals
      h = {}
      TimeTracker::CATEGORIES.each do |category|
        seconds = self.report_array.map{|i| i[:duration] if i[:category] == category}.compact.reduce(0, :+)
        h[category.to_sym] = self.seconds_to_hms(seconds)
      end
      a << "Category Totals:\n" + h.map{|k,v| "  #{k}: #{v}"}.join("\n")
      a << "\n\nCategory Details:"
      # category details
      TimeTracker::CATEGORIES.each do |category|
        a << generate_report_array_for(category)
      end
      # return report
      return a
    end

    def tally_total_hours_for(category)
      seconds = self.report_array.map{|i| i[:duration] if i[:category] == category}.compact.reduce(0, :+)
      return self.seconds_to_hms(seconds)
    end

    def generate_report_array_for(category)
      a = []
      a << "\nTotal for #{category.upcase}: #{tally_total_hours_for(category)}"
      a << "Details:"
      self.report_array.each do |entry|
        a << "  #{entry.map{|_,v| v}.join(' :: ')} (#{self.seconds_to_hms(entry[:duration])})" if (entry[:category] == category && entry[:description] != 'END OF DAY')
      end
      return a
    end

    def seconds_to_hms(seconds)
      Time.at(seconds).utc.strftime("%H:%M:%S")
    end

    def self.entries
      @@entries
    end

    def get_report_array
      report = []
      @@entries[0].each do |entry|
        report << entry if (entry[:start] >= self.start_date) && (entry[:start] <= self.end_date)
      end
      return report
    end

    def parse_file
      entries = []
      f = File.open(TimeTracker::TRACKER_FILE, 'r')
      f.each_line do |line|
        entries.push(convert_entry_string_to_hash(line)) unless line.gsub(/\n*/,'') == ''
      end
      entries = add_durations_to_entries(entries)
      return entries
    end

    def convert_entry_string_to_hash(entries)
      # expects format like '2018-02-21 16:39:27 :: category :: Description of work'
      hash = {}
      splitentry = entries.split(' :: ')
      timezone = Time.new.strftime("%:z")
      ta = splitentry[0].split(' ')[0].split('-')+splitentry[0].split(' ')[1].split(':')
      hash[:start] = Time.new(ta[0],ta[1],ta[2],ta[3],ta[4],ta[5],timezone)
      hash[:category] = splitentry[1]
      hash[:description] = splitentry[2].gsub(/\n*/,'')
      return hash
    end

    def add_durations_to_entries(entries)
      entries.each_with_index do |entry, index|
        entry[:duration] = calculate_duration(entry, entries[index+1])
      end
    end

    def calculate_duration(cur, nxt)
      if cur[:description] == 'END OF DAY' || nxt.nil?
        duration = 0
      else
        duration = nxt[:start] - cur[:start]
        self.warn_out_of_order(cur[:start]) if duration < 0
      end
      return duration
    end

    def warn_out_of_order(timestamp)
      $stderr.puts "WARNING :: an entry at '#{timestamp}' returned a negative duration. " \
                   "Are your entries out of order?"
    end

  end

end
