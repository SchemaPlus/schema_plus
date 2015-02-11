module SchemaPlus::Matchers

  class Reference
    def initialize(expected)
      @column = @on_update = @on_delete = @deferrable = @name = @to_table = @primary_key = nil
      unless expected.empty?
        @to_table, @primary_key = Array(expected).map(&:to_s)
      end
    end

    def matches?(model)
      @model = model
      if @to_table
        @result = @model.foreign_keys.select do |fk|
          fk.to_table == @to_table &&
            @primary_key.blank? ? true : fk.primary_key == @primary_key
        end
      else
        @result = @model.foreign_keys
      end
      @result.keep_if {|fk| Array.wrap(fk.column) == @column } if @column
      @result.keep_if {|fk| fk.on_update == @on_update } if @on_update
      @result.keep_if {|fk| fk.on_delete == @on_delete } if @on_delete
      @result.keep_if {|fk| fk.deferrable == @deferrable } if @deferrable
      @result.keep_if {|fk| fk.name == @name } if @name
      !@result.empty?
    end

    def failure_message(should_not = false)
      target_column = @column.present? ? "(#{Array.wrap(@column).join(', ')})" : ""
      destinantion_column = @to_table ? "#{@to_table}(#{Array.wrap(@primary_key).join(', ')})" : "anything"
      invert = should_not ? 'not' : ''
      msg = "Expected #{@model.table_name}#{target_column} to #{invert} reference #{destinantion_column}"
      with = []
      with << "on_update=#{@on_update.inspect}" if @on_update
      with << "on_delete=#{@on_delete.inspect}" if @on_delete
      with << "deferrable=#{@deferrable.inspect}" if @deferrable
      with << "name=#{@name.inspect}" if @name
      msg += " with #{with.join(" and ")}" if with.any?
      msg
    end

    def failure_message_when_negated
      failure_message(true)
    end

    def on(*column)
      @column = column.collect(&:to_s)
      self
    end

    def on_update(action)
      @on_update = action
      self
    end

    def deferrable(action)
      @deferrable = action
      self
    end

    def on_delete(action)
      @on_delete = action
      self
    end

    def with_name(action)
      @name = action
      self
    end

  end

  def reference(*expect)
    Reference.new(expect)
  end

end

