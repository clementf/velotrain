module Api
  class AccommodationsController < ApplicationController
    def index
      bounds = parse_bounds(params[:bounds])

      if bounds.blank?
        render json: { error: "bounds parameter is required" }, status: :bad_request
        return
      end

      @accommodations = Accommodation.within_bounds(bounds).where.not(price: nil).limit(300)

      render json: {
        type: "FeatureCollection",
        features: @accommodations.map do |accommodation|
          {
            type: "Feature",
            geometry: RGeo::GeoJSON.encode(accommodation.coordinates),
            properties: {
              id: accommodation.id,
              name: accommodation.name,
              accommodation_type: accommodation.accommodation_type,
              city: accommodation.city,
              zip_code: accommodation.zip_code,
              price: accommodation.price,
              url: accommodation.url,
              images: accommodation.images,
              source: accommodation.source
            }
          }
        end
      }
    end

    def show
      @accommodation = Accommodation.find(params[:id])

      # Record the outbound click
      OutboundClick.create!(accommodation: @accommodation)

      # Redirect to the accommodation's URL
      if @accommodation.url.present?
        utm_params = {
          utm_source: "velotrain",
        }
        redirect_to "#{@accommodation.url}&#{utm_params.to_query}", allow_other_host: true
      else
        head :not_found
      end
    end

    private

    def parse_bounds(bounds_param)
      return nil if bounds_param.blank?

      bounds_array = bounds_param.split(',')

      # Expecting format: southwest_lng,southwest_lat,northeast_lng,northeast_lat
      return nil unless bounds_array.length == 4

      # Convert to float and validate they are valid numbers
      bounds_array.map do |coord|
        Float(coord)
      end
    rescue ArgumentError
      nil
    end
  end
end
