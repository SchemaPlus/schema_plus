require 'singleton'

module SchemaDbDefault
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
