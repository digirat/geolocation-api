class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do
    render json: { errors: [ { detail: "Not found" } ] }, status: :not_found
  end

  rescue_from StandardError do |e|
    render json: { errors: [ { detail: e.message } ] }, status: :bad_gateway
  end
end
