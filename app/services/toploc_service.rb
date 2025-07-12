class ToplocService
  BASE_URL = 'https://toploc.com/toploc_api/listings'.freeze
  SOURCE_NAME = 'toploc'.freeze
  LISTINGS_PER_PAGE = 100

  def self.fetch_and_sync_accommodations
    new.fetch_and_sync_accommodations
  end

  def initialize
    @http_client = HTTP.timeout(30)
  end

  def fetch_and_sync_accommodations(limit: nil)
    total_synced = 0
    page = 1

    loop do
      listings_data = fetch_listings_page(page)
      break if listings_data.blank?

      accommodations_data = transform_listings_to_accommodations(listings_data)
      synced_count = upsert_accommodations_individually(accommodations_data)
      total_synced += synced_count

      # Break if we got fewer listings than expected (indicating last page)
      break if listings_data.size < LISTINGS_PER_PAGE || (limit && total_synced >= limit)

      page += 1
      sleep 0.5
    end

    Rails.logger.info "Total synced: #{total_synced} accommodations from Toploc"
  end

  private

  def fetch_listings_page(page)
    headers = {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'Authorization' => "#{Rails.application.credentials.toploc_api_key}"
    }
    response = @http_client.get(BASE_URL, params: { page: page, per_page: LISTINGS_PER_PAGE }, headers: headers)

    unless response.status.success?
      Rails.logger.error "Toploc API request failed for page #{page}: #{response.status} - #{response.body}"
      return []
    end

    data = response.parse
    listings = data.dig('data') || []

    Rails.logger.info "Fetched #{listings.size} listings from Toploc page #{page}"
    listings
  rescue HTTP::Error, JSON::ParserError => e
    Rails.logger.error "Error fetching Toploc listings page #{page}: #{e.message}"
    []
  end

  def transform_listings_to_accommodations(listings)
    listings.filter_map do |listing|
      attributes = listing['attributes']
      next unless valid_listing?(attributes)

      {
        source: SOURCE_NAME,
        external_id: listing['id'].to_s,
        name: attributes['title'],
        accommodation_type: attributes['property_type'],
        coordinates: build_coordinates(attributes['lng'], attributes['lat']),
        city: attributes['city'],
        zip_code: attributes['zip_code'],
        price: parse_price(attributes['price']),
        url: attributes['details_page_url'],
        images: attributes['images'] || [],
        created_at: Time.current
      }
    end
  end

  def valid_listing?(attributes)
    attributes.present? &&
      attributes['title'].present? &&
      attributes['lng'].present? &&
      attributes['lat'].present?
  end

  def build_coordinates(lng, lat)
    return nil if lng.blank? || lat.blank?

    "POINT(#{lng} #{lat})"
  end

  def parse_price(price_value)
    return nil if price_value.blank?

    BigDecimal(price_value.to_s)
  rescue ArgumentError
    nil
  end

  def upsert_accommodations_individually(accommodations_data)
    return 0 if accommodations_data.empty?

    synced_count = 0
    accommodations_data.each do |accommodation_data|
      begin
        Accommodation.upsert(
          accommodation_data,
          unique_by: [:source, :external_id],
          update_only: [:name, :accommodation_type, :coordinates, :city, :zip_code, :price, :url, :images]
        )
        synced_count += 1
      rescue => e
        Rails.logger.error "Failed to upsert accommodation #{accommodation_data[:external_id]}: #{e.message}"
      end
    end

    Rails.logger.info "Synced #{synced_count} accommodations from current page"
    synced_count
  end
end
