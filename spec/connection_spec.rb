require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Connection" do

  it "should re-open without failure" do
    expect {
      ActiveRecord::Base.establish_connection :schema_plus
    }.to_not raise_error
  end
end
