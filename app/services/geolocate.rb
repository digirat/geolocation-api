# frozen_string_literal: true
require "uri"
require "ipaddr"

class Geolocate
  PROVIDERS = { "ipstack" => GeoProviders::Ipstack }.freeze

  def initialize(provider: ENV.fetch("GEO_PROVIDER", "ipstack"))
    @provider = PROVIDERS.fetch(provider).new
  end

  def call(query)
    key, kind, host_or_ip = canonical_key(query)

    data = @provider.fetch(host_or_ip) # host_or_ip is either an IP string or a hostname

    Geolocation.upsert(
      {
        query: key,                       # canonical key = IP or host (dedupes variants)
        ip: data[:ip],
        url: (kind == :url ? query : nil),# keep the original URL for reference
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
    Geolocation.find_by!(query: key)
  end

  private

  # Returns [canonical_key, :ip|:url, host_or_ip]
  def canonical_key(raw)
    q = raw.to_s.strip
    raise ArgumentError, "query is blank" if q.empty?

    if ip?(q)
      return [q, :ip, q]
    end

    uri = try_parse(q)
    if uri.nil? || uri.host.nil? || uri.host.empty?
      uri = try_parse("http://#{q}")
    end
    raise ArgumentError, "unparseable URL or host" if uri.nil?

    host = uri.host&.downcase
    raise ArgumentError, "missing host" if host.nil? || host.empty?

    [host, :url, host]
  end

  def ip?(str)
    IPAddr.new(str)
    true
  rescue IPAddr::InvalidAddressError
    false
  end

  def try_parse(s)
    URI.parse(s)
  rescue URI::InvalidURIError
    nil
  end
end
