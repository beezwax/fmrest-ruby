module FmDataSpykeBuilder
  def fmdata_spyke_class(class_name: "TestClass", &block)
    Class.new(Spyke::Base).tap do |klass|
      klass.send(:include, FmData::Spyke)

      klass.define_singleton_method(:name) do
        class_name
      end

      klass.instance_eval(&block) if block_given?
    end
  end
end

RSpec.configure do |config|
  config.include FmDataSpykeBuilder
end
