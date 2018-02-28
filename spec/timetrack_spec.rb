require_relative '../lib/timetracker.rb'
RSpec.describe TimeTracker, '#test TimeTracker returns' do

  context 'class Track' do
    context 'input validation' do
      it 'correctly identifies complete category inputs' do
        expect(TimeTracker::Track.is_category?('pcp')).to be true
        expect(TimeTracker::Track.is_category?('SMOKE')).to be true
        expect(TimeTracker::Track.is_category?('aUtOmAtIoN')).to be true
        expect(TimeTracker::Track.is_category?('fooBAR')).to be false
      end
      it 'correctly identifies partial category inputs' do
        # NOTE: multiple categories with matching fragments is OUT OF SCOPE
        #       current functionality assumes all categories
        #       are uniquely identifiable from first letter on
        expect(TimeTracker::Track.is_category?('p')).to be true
        expect(TimeTracker::Track.is_category?('SM')).to be true
        expect(TimeTracker::Track.is_category?('auT')).to be true
        expect(TimeTracker::Track.is_category?('zz')).to be false
      end
    end

    context 'entry generation' do
      let(:datestamp) { Time.new.strftime('%Y-%m-%d') }
      let(:timestamp) { Time.new.strftime('%T') }
      it 'correctly generates a regular entry' do
        expected_string = "#{datestamp} #{timestamp} :: none :: test description"
        test_string = TimeTracker::Track.generate_entry('none', timestamp, 'test description')
        expect(test_string).to eq(expected_string)
      end
      it 'correctly generates an end of day entry' do
        expected_string = "#{datestamp} #{timestamp} :: none :: END OF DAY\n\n\n"
        test_string = TimeTracker::Track.generate_entry('eod', timestamp, '')
        expect(test_string).to eq(expected_string)
      end
    end

    context 'pending tests' do
      pending
      it 'tests write_line_to_file' do
        expect false
      end
      it 'tests description_present?' do
        expect false
      end
      it 'tests set_valid_category' do
        # stub stdin
        expect false
      end
      it 'tests set_valid_description' do
        # stub stdin
        expect false
      end
      it 'tests get_input_from_stdin' do
        # stub stdin
        expect false
      end
    end
  end

  context 'class Report' do
    context 'report generation' do
      pending
      it 'generates a report for the entire file' do
        expect false
      end
      it 'generates a report for a time period in the tracker file' do
        expect false
      end
      it 'generates a report for a time period not in the tracker file' do
        expect false
      end
    end
  end

end
