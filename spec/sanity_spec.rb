require 'spec_helper'


describe "Sanity Check" do

  it "database is connected" do
    expect(ActiveRecord::Base).to be_connected
  end

end
