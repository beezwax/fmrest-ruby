require "spec_helper"

RSpec.describe FmRest::V1::Utils do
  let(:extendee) { Object.new.tap { |obj| obj.extend(described_class) } }

  describe "#convert_script_params" do
    it "converts a string argument into a single script options hash" do
      expect(extendee.convert_script_params("Lone Script")).to eq(script: "Lone Script")
    end

    it "converts a symbol argument into a single script options hash" do
      expect(extendee.convert_script_params(:lone_script)).to eq(script: "lone_script")
    end

    it "converts an array argument into a single script options hash with params" do
      expect(extendee.convert_script_params(["Lone Script", "but with params"])).to eq(script: "Lone Script", "script.param": "but with params")
    end

    it "converts an array argument with symbols into a single script options hash with params" do
      expect(extendee.convert_script_params([:lone_script, :with_params])).to eq(script: "lone_script", "script.param": :with_params)
    end

    it "converts a hash with prerequest, presort and after keys into a script options hash with all three scripts" do
      expect(extendee.convert_script_params(
        prerequest: "Prerequest Script",
        presort:    "Presort Script",
        after:      "After Script"
      )).to eq(
        script:              "After Script",
        "script.presort":    "Presort Script",
        "script.prerequest": "Prerequest Script"
      )
    end

    it "converts a hash with prerequest, presort and after keys with arrays into a script options hash with all three scripts and their params" do
      expect(extendee.convert_script_params(
        prerequest: ["Prerequest Script", "prerequest param"],
        presort:    ["Presort Script", "presort param"],
        after:      ["After Script", "after param"]
      )).to eq(
        script:                    "After Script",
        "script.param":            "after param",
        "script.presort":          "Presort Script",
        "script.presort.param":    "presort param",
        "script.prerequest":       "Prerequest Script",
        "script.prerequest.param": "prerequest param"
      )
    end

    it "raises ArgumentError if given a hash with an invalid key" do
      expect { extendee.convert_script_params(foo: "bar") }.to raise_error(ArgumentError, /\AInvalid script option/)
    end

    it "raises ArgumentError if given a hash with invalid values" do
      expect { extendee.convert_script_params(after: false) }.to raise_error(ArgumentError, /\AScript arguments/)
    end
  end
end
