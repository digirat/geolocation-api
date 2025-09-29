require "ipaddr"
require "resolv"

module GeoProviders
  class Ipstack < Base
    def initialize(api_key: ENV["IPSTACK_API_KEY"], base_url: ENV.fetch("IPSTACK_BASE_URL", "http://api.ipstack.com"))
      @api_key = api_key
      @client = Faraday.new(base_url) { |f| f.request :url_encoded; f.response :raise_error; f.adapter Faraday.default_adapter }
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
