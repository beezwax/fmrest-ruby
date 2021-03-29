require "spec_helper"
require "active_support/time"

RSpec.describe FmRest::V1::Dates do
  let(:extendee) { Object.new.tap { |obj| obj.extend(described_class) } }

  describe ".extended" do
    it "instantiates memoization variables in the target module" do
      expect(extendee.instance_variable_get(:@date_strptime)).to eq({})
      expect(extendee.instance_variable_get(:@date_regexp)).to eq({})
    end
  end

  describe "#fm_date_to_strptime_format" do
    it "converts 'MM/dd/yyyy HH:mm:ss' to '%m/%d/%Y %H:%M:%S'" do
      expect(extendee.fm_date_to_strptime_format("MM/dd/yyyy HH:mm:ss")).to eq("%m/%d/%Y %H:%M:%S")
    end

    it "doesn't convert 'MdyHms'" do
      expect(extendee.fm_date_to_strptime_format("MdyHms")).to eq("MdyHms")
    end
  end

  describe "#fm_date_to_regexp" do
    let(:expected_re) { %r{\A(?:0[1-9]|1[012])/(?:0[1-9]|[12][0-9]|3[01])/\d{4} (?:[01]\d|2[0123]):[0-5]\d:[0-5]\d\Z} }

    it "converts 'MM/dd/yyyy HH:mm:ss' to '%m/%d/%Y %H:%M:%S'" do
      expect(extendee.fm_date_to_regexp("MM/dd/yyyy HH:mm:ss")).to eq(expected_re)
    end

    it "produces a regexp that properly matches valid timestamps" do
      expect(expected_re.match?("12/24/2009 11:11:11")).to eq(true)
      expect(expected_re.match?("01/01/2009 23:11:11")).to eq(true)
    end

    it "produces a regexp that rejects invalid timestamps" do
      expect(expected_re.match?("13/24/2009 11:11:11")).to be(false)
      expect(expected_re.match?("12/32/2009 11:11:11")).to be(false)
      expect(expected_re.match?("12/24/2009 25:11:11")).to be(false)
      expect(expected_re.match?("12/24/2009 11:61:11")).to be(false)
      expect(expected_re.match?("12/24/2009 11:11:61")).to be(false)
    end

    it "doesn't convert 'MdyHms'" do
      expect(extendee.fm_date_to_regexp("MdyHms")).to eq(/\AMdyHms\Z/)
    end
  end

  describe "#local_offset_for_datetime" do
    it "returns the right offset for the given date, observing daytime saving" do
      # Take advantage of ActiveSupport's TimeZone for testing
      # independently of the system timezone
      Time.use_zone("Pacific Time (US & Canada)") do
        # Pacific Daylight Saving Time (observed until Nov 1 2020, 2 AM, or 8 AM UTC)
        pdt_dt = DateTime.new(2020, 11, 1, 8, 59, 59)
        # Pacific Standard Time takes effect at 9 AM UTC
        pst_dt = DateTime.new(2020, 11, 1, 9, 0, 0)

        expect(extendee.local_offset_for_datetime(pdt_dt)).to eq(Rational(-7, 24))
        expect(extendee.local_offset_for_datetime(pst_dt)).to eq(Rational(-8, 24))
      end
    end

    context "when ActiveSupport's TimeZone is not present" do
      it "returns the right offset for the given date, observing daytime saving" do
        # Force the check for ActiveSupport
        allow_any_instance_of(Time).to receive(:respond_to?).with(:in_time_zone).and_return(false)

        orig_tz = ENV["TZ"]
        ENV["TZ"] = "US/Pacific"

        begin
          # Pacific Daylight Saving Time (observed until Nov 1 2020, 2 AM, or 8 AM UTC)
          pdt_dt = DateTime.new(2020, 11, 1, 8, 59, 59)
          # Pacific Standard Time takes effect at 9 AM UTC
          pst_dt = DateTime.new(2020, 11, 1, 9, 0, 0)

          expect(extendee.local_offset_for_datetime(pdt_dt)).to eq(Rational(-7, 24))
          expect(extendee.local_offset_for_datetime(pst_dt)).to eq(Rational(-8, 24))
        ensure
          ENV["TZ"] = orig_tz
        end
      end
    end
  end

  describe "#datetime_classes" do
    context "with no FmRest::StringDateTime defined" do
      it "returns an array of datetime-representing classes without FmRest::StringDateTime" do
        if defined?(FmRest::StringDateTime)
          @old_string_date_time = FmRest::StringDateTime
          FmRest.send(:remove_const, :StringDateTime)
        end

        expect(extendee.datetime_classes).to eq([DateTime, Time])

        FmRest::StringDateTime = @old_string_date_time if @old_string_date_time
      end
    end

    context "with FmRest::StringDateTime defined" do
      it "returns an array of datetime-representing classes with FmRest::StringDateTime" do
        mock_string_date_time = double(:StringDateTimeClass)

        if defined?(FmRest::StringDateTime)
          @old_string_date_time = FmRest::StringDateTime
          FmRest.send(:remove_const, :StringDateTime)
        end

        FmRest::StringDateTime = mock_string_date_time

        expect(extendee.datetime_classes).to eq([DateTime, Time, mock_string_date_time])

        if @old_string_date_time
          FmRest::StringDateTime = @old_string_date_time
        else
          FmRest.send(:remove_const, :StringDateTime)
        end
      end
    end
  end

  describe "#date_classes" do
    context "with no FmRest::StringDate defined" do
      it "returns an array of date-representing classes without FmRest::StringDate" do
        if defined?(FmRest::StringDate)
          @old_string_date = FmRest::StringDate
          FmRest.send(:remove_const, :StringDate)
        end

        expect(extendee.date_classes).to eq([Date])

        FmRest::StringDate = @old_string_date if @old_string_date
      end
    end

    context "with FmRest::StringDate defined" do
      it "returns an array of date-representing classes with FmRest::StringDate" do
        mock_string_date = double(:StringDateClass)

        if defined?(FmRest::StringDate)
          @old_string_date = FmRest::StringDate
          FmRest.send(:remove_const, :StringDate)
        end

        FmRest::StringDate = mock_string_date

        expect(extendee.date_classes).to eq([Date, mock_string_date])

        if @old_string_date
          FmRest::StringDate = @old_string_date
        else
          FmRest.send(:remove_const, :StringDate)
        end
      end
    end
  end

  describe "#convert_datetime_timezone" do
    let(:datetime) { DateTime.civil(2020, 8, 1, 13, 31, 9, '-1') }

    subject { extendee.convert_datetime_timezone(datetime, timezone).offset }

    context "when :timezone is set to nil" do
      let(:timezone) { nil }

      it "returns the same datetime object" do
        is_expected.to eq(datetime.offset)
      end
    end

    [:utc, "utc"].each do |tz|
      context "when :timezone is set to #{tz.inspect}" do
        let(:timezone) { tz }

        it "returns the datetime with offset converted to zero" do
          is_expected.to eq(0)
        end
      end
    end

    [:local, "local"].each do |tz|
      context "when :timezone is set to #{tz.inspect}" do
        let(:timezone) { tz }

        it "returns the datetime converted to local timezone" do
          # Take advantage of ActiveSupport's TimeZone for testing
          # independently of the system timezone
          Time.use_zone("Pacific Time (US & Canada)") do
            # On this date it's PDT, so UTC offset is -7hs
            is_expected.to eq(Rational(-7, 24))
          end
        end
      end
    end
  end
end
