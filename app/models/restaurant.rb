class Restaurant
  include Mongoid::Document
  include Mongoid::Timestamps
  include Geolocatable

  field :name, type: :string
  field :address, type: :string
  field :zipcode, type: :string
  field :rating, type: :float
  field :category, type: :string
  field :total_ratings, type: :integer
  field :price_level, type: :string
  field :cuisine, type: :string
  field :enriched_data, type: :hash

  def set_price_level(level)
    return if level.nil?
    
    self.price_level = case level.to_i
      when 1 then "$"
      when 2 then "$$"
      when 3 then "$$$"
      when 4 then "$$$$"
      else "N/A"
    end
  end
end