class GeolocationsController < ApplicationController
  before_action :require_api_key, if: -> { ENV["API_KEY"].present? }

  def index
    render json: GeolocationSerializer.new(Geolocation.order(created_at: :desc)).serializable_hash
  end

  def show
    record = Geolocation.find_by!(query: params[:id])
    render json: GeolocationSerializer.new(record).serializable_hash
  end

  def create
    query = params.require(:data).require(:attributes).permit(:query)[:query]
    record = Geolocate.new.call(query)
    render json: GeolocationSerializer.new(record).serializable_hash, status: :created
  rescue ActionController::ParameterMissing
    render json: { errors: [ { detail: "Missing data.attributes.query" } ] }, status: :unprocessable_entity
  end

  def destroy
    Geolocation.find_by!(query: params[:id]).destroy!
    head :no_content
  end

  private

  def require_api_key
    key = request.headers["X-API-Key"]
    render(json: { errors: [ { detail: "Unauthorized" } ] }, status: :unauthorized) unless ActiveSupport::SecurityUtils.secure_compare(key.to_s, ENV["API_KEY"].to_s)
  end
end
