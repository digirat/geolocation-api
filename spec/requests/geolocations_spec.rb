require "rails_helper"

RSpec.describe "Geolocations", type: :request do
  let(:api_key) { "secret" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("API_KEY").and_return(api_key)
    allow(ENV).to receive(:[]).with("IPSTACK_API_KEY").and_return("testkey")
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("GEO_PROVIDER", "ipstack").and_return("ipstack")

    stub_request(:get, %r{\Ahttp://api\.ipstack\.com/8\.8\.8\.8\?access_key=testkey})
      .to_return(status: 200, body: {
        ip: "8.8.8.8",
        city: "Mountain View",
        region_name: "California",
        country_name: "United States",
        latitude: 37.386,
        longitude: -122.0838
      }.to_json)
  end

  it "creates and returns a geolocation (IP)" do
    post "/geolocations",
         params: { data: { type: "geolocations", attributes: { query: "8.8.8.8" } } }.to_json,
         headers: { "CONTENT_TYPE" => "application/json", "X-API-Key" => api_key }

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body.dig("data", "attributes", "ip")).to eq("8.8.8.8")
  end
end
