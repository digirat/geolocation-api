# frozen_string_literal: true
require "ipaddr"
require "resolv"
require "oj"
require "faraday"
require "faraday/retry"

module GeoProviders
  class Ipstack < Base
    def initialize(api_key: ENV["IPSTACK_API_KEY"], base_url: ENV.fetch("IPSTACK_BASE_URL", "http://api.ipstack.com"))
      @api_key = api_key
      @client = Faraday.new(base_url) do |f|
        f.request :url_encoded
        f.request :retry,
                  max: 2,
                  interval: 0.2,
                  backoff_factor: 2,
                  retry_statuses: [429, 500, 502, 503, 504]
        f.response :raise_error
        f.options.timeout = 5
        f.options.open_timeout = 2
        f.adapter Faraday.default_adapter
      end
    end

    # Accepts either an IP string or a hostname (already normalized by the caller).
    def fetch(host_or_ip)
      ip = ip?(host_or_ip) ? host_or_ip : resolve!(host_or_ip)

      resp = @client.get("/#{ip}", access_key: @api_key)
      body = Oj.load(resp.body)

      if body.is_a?(Hash) && body["success"] == false
        raise StandardError, (body.dig("error", "info") || "ipstack error")
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
    rescue Resolv::ResolvError
      raise ArgumentError, "could not resolve host"
    rescue Faraday::Error => e
      raise StandardError, "ipstack http error: #{e.message}"
    end

    private

    def ip?(str)
      IPAddr.new(str)
      true
    rescue IPAddr::InvalidAddressError
      false
    end

    def resolve!(host)
      # Will raise Resolv::ResolvError if it cannot resolve
      Resolv.getaddress(host)
    end
  end
end
