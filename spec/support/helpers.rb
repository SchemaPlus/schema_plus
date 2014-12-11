module SchemaPlusHelpers
  extend self

  def suppress_messages
    ActiveRecord::Migration.suppress_messages { yield }
  end

end
