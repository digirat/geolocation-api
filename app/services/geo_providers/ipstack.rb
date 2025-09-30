require "ipaddr"
require "resolv"
require "faraday/retry"

module GeoProviders
  class Ipstack < Base
    def initialize(api_key: ENV["IPSTACK_API_KEY"], base_url: ENV.fetch("IPSTACK_BASE_URL", "http://api.ipstack.com"))
      @api_key = api_key
      @client = Faraday.new(base_url) do |f|
      f.request :url_encoded

      # Retry on transient errors
      f.request :retry,
        max: 2,
        interval: 0.2,
        backoff_factor: 2,
        retry_statuses: [429, 500, 502, 503, 504]

      # Raise exceptions for 4xx/5xx
      f.response :raise_error

      # Set timeouts
      f.options.timeout = 5         # seconds for whole request
      f.options.open_timeout = 2    # seconds for TCP connect

      f.adapter Faraday.default_adapter
    end

    end

    def fetch(query)
      ip = ip_from(query)
      resp = @client.get("/#{ip}", access_key: @api_key)
      body = Oj.load(resp.body)

      if body.is_a?(Hash) && body["success"] == false
        raise StandardError, body.dig("error", "info") || "ipstack error"
      end

      {
        ip: body["ip"],
        city: body["city"],
        region: body["region_name"],
        country: body["country_name"],
        latitude: body["latitude"],
        longitude: body["longitude"],
        raw: body,
        provider: "ipstack",
        status: "ok"
      }
    rescue Faraday::Error => e
      raise StandardError, "ipstack http error: #{e.message}"
    end

    private

    def ip_from(query)
      return query if ip?(query)
      host = URI.parse(query).host rescue query
      Resolv.getaddress(host)
    end

    def ip?(str)
      IPAddr.new(str) && true
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end
