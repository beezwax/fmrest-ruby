require "support/fmrest_dummy_config"

module FmRestSpykeBuilder
  def fmrest_spyke_class(class_name: "TestClass", &block)
    Class.new(FmRest::Spyke::Base).tap do |klass|
      klass.fmrest_config = FMREST_DUMMY_CONFIG

      klass.define_singleton_method(:name) do
        class_name
      end

      klass.instance_eval(&block) if block_given?
    end
  end
end

RSpec.configure do |config|
  config.include FmRestSpykeBuilder
end
