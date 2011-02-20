# ported from rspec-rails
# There is no reason to install whole gem as we
# need only that tiny helper
module ::ActiveModel::Validations

  def error_on(attribute)
    self.valid?
    [self.errors[attribute]].flatten.compact
  end

  alias :errors_on :error_on

end
