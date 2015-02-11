module SchemaPlus::Matchers

  class HaveIndex

    def initialize(expectation, options = {})
      set_required_columns(expectation)
      @unique = options.delete(:unique)
      @name   = options.delete(:name)
    end

    def matches?(model)
      @too_many = nil
      @model = model
      indexes = @model.indexes.select { |index| index.columns.to_set == @required_columns }
      if indexes.length > 1
        @too_many = indexes.length
        return false
      end
      index = indexes.first
      return index && (@unique ? index.unique : true) && (@name ? index.name == @name.to_s : true)
    end

    def failure_message(should_not = false)
      invert = should_not ? "not to" : "to"
      what = ""
      what += "unique " if @unique
      what += "named '{@name}'" if @name
      msg = "Expected #{@model.table_name} #{invert} contain one #{what}index on #{@required_columns.entries.inspect}"
      msg += "; found #{@too_many} indexes" if @too_many
      msg
    end

    def failure_message_when_negated
      failure_message(true)
    end

    def on(expectation)
      set_required_columns(expectation)
      self
    end

    private
    def set_required_columns(expectation)
      @required_columns = Array(expectation).collect(&:to_s).to_set
    end

  end

  def have_index(*expectation)
    options = expectation.extract_options!
    HaveIndex.new(expectation, options)
  end

  def have_unique_index(*expectation)
    options = expectation.extract_options!
    options[:unique] = true
    HaveIndex.new(expectation, options)
  end

end
