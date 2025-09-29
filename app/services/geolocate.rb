class Geolocate
  PROVIDERS = { "ipstack" => GeoProviders::Ipstack }.freeze

  def initialize(provider: ENV.fetch("GEO_PROVIDER", "ipstack"))
    @provider = PROVIDERS.fetch(provider).new
  end

  def call(query)
    data = @provider.fetch(query)
    Geolocation.upsert(
      {
        query: query,
        ip: data[:ip],
        url: url_from(query),
        city: data[:city],
        region: data[:region],
        country: data[:country],
        latitude: data[:latitude],
        longitude: data[:longitude],
        provider: data[:provider],
        status: data[:status],
        raw: data[:raw],
        updated_at: Time.current,
        created_at: Time.current
      },
      unique_by: :query
    )
    Geolocation.find_by!(query: query)
  end

  private

  def url_from(query)
    query =~ %r{\Ahttps?://} ? query : nil
  end
end
