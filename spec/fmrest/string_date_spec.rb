require "spec_helper"

require "fmrest/string_date"

RSpec.shared_examples "a StringDateish" do
  describe "#initialize" do
    it "freezes the string" do
      expect(subject).to be_frozen
    end

    it "raises an FmRest::StringDate::InvalidDate if date parsing fails" do
      expect { described_class.new("", "") }.to raise_error(FmRest::StringDate::InvalidDate)
    end
  end

  describe "#is_a?" do
    it "returns true if given String" do
      expect(subject.is_a?(String)).to eq(true)
    end

    it "returns true if given Date" do
      expect(subject.is_a?(Date)).to eq(true)
    end

    it "returns true if given FmRest::StringDate" do
      expect(subject.is_a?(described_class)).to eq(true)
    end

    it "returns false if given something it's not" do
      expect(subject.is_a?(Hash)).to eq(false)
    end

    it "is aliased as #kind_of?" do
      expect(described_class.instance_method(:is_a?)).to eq(described_class.instance_method(:kind_of?))
    end
  end

  describe "#to_date" do
    it "returns a Date" do
      expect(subject.to_date.class).to eq(Date)
    end

    it "returns a date matching the date string" do
      expect(subject.to_date).to eq(dateish.to_date)
    end
  end

  describe "#to_datetime" do
    it "returns a DateTime" do
      expect(subject.to_datetime.class).to eq(DateTime)
    end
  end

  describe "#to_time" do
    it "returns a Time" do
      expect(subject.to_time.class).to eq(Time)
    end
  end

  describe "#inspect" do
    it "returns a custom format string representation" do
      expect(subject.inspect).to eq("#<#{described_class.name} #{dateish.inspect} - #{str_dateish.inspect}>")
    end
  end

  describe "#<=>" do
    it "compares dates when given a Date" do
      expect(subject.<=>(dateish)).to eq(0)
    end

    it "compares dates when given a Numeric (Astronomical Julian Day)" do
      expect(subject.<=>(dateish.ajd)).to eq(0)
    end

    it "compares strings when given a String" do
      expect(subject<=>(str_dateish)).to eq(0)
    end
  end

  describe "#+" do
    it "adds to the date if given a Numeric" do
      expect(subject + 1).to eq(dateish + 1)
    end

    it "concatenates to the string if given a String" do
      expect(subject + " indeed").to eq("#{str_dateish} indeed")
    end
  end

  describe "#<<" do
    it "substracts a month from the date if given a Numeric" do
      expect(subject << 1).to eq(dateish << 1)
    end

    it "raises a FrozenError if given a String" do
      expect { subject << "BOOM!" }.to raise_error(FrozenError)
    end
  end

  describe "#==" do
    it "compares against the date if given a Date" do
      expect(subject == dateish).to eq(true)
    end

    it "compares against the date if given a Numeric (Astronomical Julian Day)" do
      expect(subject == dateish.ajd).to eq(true)
    end

    it "compares against the string if given a String" do
      expect(subject == str_dateish).to eq(true)
    end

    it "is aliased as #===" do
      expect(described_class.instance_method(:==)).to eq(described_class.instance_method(:===))
    end
  end

  describe "#upto" do
    it "iterates through dates if given a Date" do
      enum = subject.upto(dateish + 2)
      enum.next
      expect(enum.next).to eq(dateish + 1)
    end

    it "iterates through dates if given a Numeric" do
      enum = subject.upto((dateish + 2).ajd)
      enum.next
      expect(enum.next).to eq(dateish + 1)
    end

    it "iterates through strings if given a String" do
      enum = subject.upto("Z" * str_dateish.size)
      enum.next
      expect(enum.next).to eq(str_dateish.next)
    end
  end

  describe "#between?" do
    it "compares the date if given two dates" do
      expect(subject.between?(dateish - 1, dateish + 1)).to eq(true)
    end

    it "compares the date if given two numbers" do
      expect(subject.between?((dateish - 1).ajd, (dateish + 1).ajd)).to eq(true)
    end

    it "compares the string if given two strings" do
      expect(subject.between?("", str_dateish.next)).to eq(true)
    end
  end

  # All methods natively provided by Date, but not by String
  [
    :-, :>>, :ajd, :amjd, :asctime, :ctime, :cwday, :cweek, :cwyear, :day,
    :day_fraction, :downto, :england, :friday?, :gregorian, :gregorian?,
    :httpdate, :iso8601, :italy, :jd, :jisx0301, :julian, :julian?, :ld,
    :leap?, :marshal_dump, :marshal_load, :mday, :mjd, :mon, :monday?, :month,
    :new_start, :next_day, :next_month, :next_year, :prev_day, :prev_month,
    :prev_year, :rfc2822, :rfc3339, :rfc822, :saturday?, :start, :step,
    :strftime, :sunday?, :thursday?, :to_date, :to_datetime, :to_time,
    :tuesday?, :wday, :wednesday?, :xmlschema, :yday, :year
  ].each do |date_meth|
    describe "##{date_meth}" do
      it "responds" do
        expect(subject.respond_to?(date_meth)).to eq(true)
      end
    end
  end

  # Pick one Date method to check that method_missing is working
  describe "#year" do
    it "returns the date's year" do
      expect(subject.year).to eq(year)
    end
  end
end

RSpec.describe FmRest::StringDate do
  let(:year) { 2020 }
  let(:month) { 4 }
  let(:day) { 22 }

  let(:dateish) { Date.civil(year, month, day) }
  let(:str_dateish) { "#{year}-#{month}-#{day}" }
  let(:format) { "%Y-%m-%d" }

  subject { described_class.new(str_dateish, format) }

  it_behaves_like "a StringDateish"

  describe "#in_time_zone" do
    it "forwards to the date" do
      expect(subject.to_date).to receive(:in_time_zone)
      subject.in_time_zone
    end
  end
end

RSpec.describe FmRest::StringDateTime do
  let(:year) { 2020 }
  let(:month) { 4 }
  let(:day) { 22 }
  let(:hour) { 11 }
  let(:minutes) { 11 }
  let(:seconds) { 11 }

  let(:dateish) { DateTime.civil(year, month, day, hour, minutes, seconds) }
  let(:str_dateish) { "#{year}-#{month}-#{day} #{hour}:#{minutes}:#{seconds}" }
  let(:format) { "%Y-%m-%d %H:%M:%S" }

  subject { described_class.new(str_dateish, format) }

  it_behaves_like "a StringDateish"

  describe "#is_a?" do
    it "returns true if given DateTime" do
      expect(subject.is_a?(DateTime)).to eq(true)
    end
  end

  describe "#to_datetime" do
    it "matches the time" do
      expect(subject.to_datetime).to eq(dateish)
    end
  end

  describe "#in_time_zone" do
    it "forwards to the date-time" do
      expect(subject.to_datetime).to receive(:in_time_zone)
      subject.in_time_zone
    end
  end
end
