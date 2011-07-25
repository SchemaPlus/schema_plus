require 'set'
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rails/generators'
require 'generators/schema_plus/install_generator'

describe SchemaPlus::Generators::InstallGenerator do

  before do
    # Rails::Generators::TestCase is a class
    # so unfortunately we can't easily use it with RSpec
    # This is a quick workaround.
    # TODO: move to the matcher
    generator = Class.new(Rails::Generators::TestCase)
    generator.generator_class = subject.class
    generator.destination File.expand_path('../tmp', __FILE__)
    generator.setup :prepare_destination
    g = generator.new("InstallGeneratorTest")
    g.run_generator(%w[schema_plus::install])
    @expected_path = File.join(g.destination_root, "config/initializers/schema_plus.rb")
  end

  it "should generate initializer" do
    File.exists?(@expected_path).should be_true
  end

  it "should have initial content" do
    File.read(@expected_path).should match /SchemaPlus.config/
  end

end

