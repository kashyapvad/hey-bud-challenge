module Geolocatable
  extend ActiveSupport::Concern
   include Mongoid::Geospatial
   include Geocoder::Model::Mongoid

  included do
    field :geo_coordinates, type: Mongoid::Geospatial::Point, sphere: true
    field :timezone
  end

  def geo_address
    a = "#{self[:name]}, " if self[:name]
    "#{a} - #{self[:address]}"
  end

  def geo_locate
    return unless !address.nil? and address.count("a-zA-Z") > 0
    self[:geo_coordinates] = Geocoder.coordinates(address)
  end
end
