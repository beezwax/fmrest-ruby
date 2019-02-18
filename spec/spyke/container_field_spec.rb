RSpec.describe FmRest::Spyke::ContainerField do
  describe "#initialize" do
    xit "sets base and name"
  end

  describe "#name" do
    xit "returns the name"
  end

  describe "#url" do
    xit "returns the url for the container field"
  end

  describe "#download" do
    xit "returns an IO object with the contained file"
  end

  describe "#upload" do
    xit "raises error if record is not persisted"
    xit "uploads the given filename or IO to the container"
    xit "accepts :repetition option"
    xit "accepts :content_type option"
    xit "accepts :filename option"
    xit "uses filename_or_io.original_filename by default"
    xit "updates mod_id"
  end
end
