class String
  def to_boolean
    token = self.squish.downcase
    token = "false" if ["no", "n", "0", "false"].include? token
    return false if token.empty?
    ActiveModel::Type::Boolean.new.cast(token)
  end
  alias_method :to_bool, :to_boolean

  def to_key
    squish.underscore.gsub(".","_").gsub(" ","_").gsub(/_+/, "_")
  end

  def yesno
    if [:true, :yes].include? squish.downcase.to_sym
      "Yes"
    else
      "No"
    end
  end

  def to_downcase_sym
    token = self.squish.downcase
    return nil if token.empty?
    token.to_sym
  end

  def iso8601
    Date.parse(self).iso8601
  end
end