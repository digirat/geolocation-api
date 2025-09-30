class GeolocationsController < ApplicationController
  before_action :require_api_key, if: -> { ENV["API_KEY"].present? }

  def index
    render json: GeolocationSerializer.new(Geolocation.order(created_at: :desc)).serializable_hash
  end

  def show
    key = canonical_key(params[:id])
    record = Geolocation.find_by!(query: key)
    render json: GeolocationSerializer.new(record).serializable_hash
  rescue ArgumentError => e
    render json: { errors: [ { detail: e.message } ] }, status: :unprocessable_entity
  end

  def create
    query = params.require(:data).require(:attributes).permit(:query)[:query]
    record = Geolocate.new.call(query)
    render json: GeolocationSerializer.new(record).serializable_hash, status: :created
  rescue ActionController::ParameterMissing
    render json: { errors: [ { detail: "Missing data.attributes.query" } ] }, status: :unprocessable_entity
  end

  def destroy
    key = canonical_key(params[:id])
    Geolocation.find_by!(query: key).destroy!
    head :no_content
  rescue ArgumentError => e
    render json: { errors: [ { detail: e.message } ] }, status: :unprocessable_entity
  end

  private

  def require_api_key
    key = request.headers["X-API-Key"]
    render(json: { errors: [ { detail: "Unauthorized" } ] }, status: :unauthorized) unless ActiveSupport::SecurityUtils.secure_compare(key.to_s, ENV["API_KEY"].to_s)
  end

  # Normalizes an ID or query into a canonical key:
  # - IP stays as-is
  # - URL (any case, with path/query) => downcased host
  # - bare host (example.com) is accepted
  def canonical_key(raw)
    q = raw.to_s.strip
    raise ArgumentError, "query is blank" if q.empty?

    # IP stays as-is
    begin
      IPAddr.new(q)
      return q
    rescue IPAddr::InvalidAddressError
      # not an IP, keep going
    end

    # Try URL, then bare host
    uri = try_parse_uri(q) || try_parse_uri("http://#{q}")
    raise ArgumentError, "unparseable URL or host" unless uri
    raise ArgumentError, "unsupported scheme" unless %w[http https].include?(uri.scheme)

    host = uri.host&.downcase
    raise ArgumentError, "missing host" if host.blank?
    host
  end


  def try_parse_uri(str)
    URI.parse(str)
  rescue URI::InvalidURIError
    nil
  end
end
