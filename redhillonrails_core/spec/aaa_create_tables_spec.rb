require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# This is not a test really. It just here to create schema
# The filename begins with "aaa" to ensure this is executed initially

ActiveRecord::Migration.suppress_messages do
  load_schema
end

