module AutomaticForeignKeyMatchers

  class HaveIndex

    def initialize(expectation, options = {})
      set_required_columns(expectation, options)
    end

    def matches?(model)
      @model = model
      @model.indexes.any? do |index|
        index.columns.to_set == @required_columns &&
          (@unique  ? index.unique : true) &&
          (@name    ? index.name == @name.to_s : true)
      end
    end

    def failure_message_for_should(should_not = false)
      invert = should_not ? "not to" : ""
      "Expected #{@model.table_name} to #{invert} contain index on #{@required_columns.entries.inspect}"
    end

    def failure_message_for_should_not
      failure_message_for_should(true)
    end

    def on(expectation)
      set_required_columns(expectation)
      self
    end

    private
    def set_required_columns(expectation, options = {})
      @required_columns = Array(expectation).collect(&:to_s).to_set
      @unique = options.delete(:unique)
      @name   = options.delete(:name)
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
