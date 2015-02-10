require 'singleton'

module SchemaPlusDbDefault
  class DbDefault
    include Singleton
    def to_s
      'DEFAULT'
    end
    def id
      self
    end
    def quoted_id
      self
    end
  end
  DB_DEFAULT = DbDefault.instance
end

::ActiveRecord.const_set(:DB_DEFAULT, DB_DEFAULT)
