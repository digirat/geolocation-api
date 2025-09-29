class GeolocationSerializer
  include JSONAPI::Serializer
  set_type :geolocation
  attributes :query, :ip, :url, :city, :region, :country, :latitude, :longitude, :provider, :status, :created_at, :updated_at
end
