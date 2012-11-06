module PG
  class Connection
    CONNECTION_OK = 1
    def self.connect(*args)
      new
    end
    def server_version
      90102
    end
    def status
      CONNECTION_OK
    end

    def exec(sql)
      puts "*** #{sql.gsub(/\n/, "\n  * ")}"
      @result = case sql
                when "SHOW client_min_messages" then Result.new([{client_min_messages: 0}])
                else Result.new
                end
    end

    def async_exec(sql)
      exec(sql)
    end

    def get_last_result
      @result
    end
    def query(sql)
      case sql
      when "SELECT 1" then 1
      end
    end
    def self.quote_ident(str)
      str
    end
    def escape(str)
      str
    end
    def prepare(key, sql)
      (@prepared ||={})[key] = sql.dup
    end
    def send_query_prepared(key, binding)
      sql = @prepared[key]
      binding.each_with_index do |val, i|
        sql = sql.gsub(/\$#{i+1}/m, val.inspect)
      end
      async_exec(sql)
    end
    def block
    end
  end
  class Result
    def initialize(array=[{}])
      @array = array
    end
    def nfields
      @array[0].size
    end
    def fields
      @array.first.keys
    end
    def values
      @array.map(&:values)
    end
    def ftype(i)
      nil
    end
    def first
      @array.first
    end
    def clear
    end

  end
  class Error < ::RuntimeError
  end
end

# Backward-compatible alias
PGconn = PG::Connection

PGError = PG::Error
