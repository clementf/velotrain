require 'rails_helper'

RSpec.describe ToplocService do
  let(:service) { described_class.new }
  let(:updated_since) { 1.day.ago }
  let(:sample_listing) do
    {
      "id" => "1951",
      "type" => "holidu_listing",
      "attributes" => {
        "id" => 1951,
        "title" => "La mer est belle",
        "property_type" => "GITE",
        "images" => [
          "https://img.holidu.com/images/5b44d323-9622-4d84-80c4-1fbcb1e763f4/t.jpg",
          "https://img.holidu.com/images/09cef4b6-8265-4989-ab0a-b2bd69c7ec17/t.jpg"
        ],
        "lat" => "47.618912",
        "lng" => "-3.16727",
        "zip_code" => "56410",
        "city" => "Erdeven",
        "price" => "119.0",
        "details_page_url" => "https://toploc.holidu.com//d/51176975"
      }
    }
  end

  describe '.fetch_and_sync_accommodations' do
    it 'creates a new instance and calls fetch_and_sync_accommodations' do
      expect_any_instance_of(described_class).to receive(:fetch_and_sync_accommodations)
      described_class.fetch_and_sync_accommodations
    end
  end

  describe '#fetch_and_sync_accommodations' do
    context 'when API returns data' do
      before do
        stub_request(:get, described_class::BASE_URL)
          .with(query: hash_including(page: '1', per_page: '100'))
          .to_return(
            status: 200,
            body: { data: [sample_listing] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        
        stub_request(:get, described_class::BASE_URL)
          .with(query: hash_including(page: '2', per_page: '100'))
          .to_return(
            status: 200,
            body: { data: [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fetches listings and upserts accommodations' do
        expect(Accommodation).to receive(:upsert).with(
          hash_including(
            source: 'toploc',
            external_id: '1951',
            name: 'La mer est belle',
            accommodation_type: 'GITE'
          ),
          any_args
        )

        service.fetch_and_sync_accommodations
      end

      it 'logs successful sync' do
        allow(Accommodation).to receive(:upsert)
        expect(Rails.logger).to receive(:info).with("Fetched 1 listings from Toploc page 1")
        expect(Rails.logger).to receive(:info).with("Synced 1 accommodations from current page")
        expect(Rails.logger).to receive(:info).with("Total synced: 1 accommodations from Toploc")

        service.fetch_and_sync_accommodations
      end
    end

    context 'when API returns no data' do
      before do
        stub_request(:get, described_class::BASE_URL)
          .with(query: hash_including(page: '1', per_page: '100'))
          .to_return(
            status: 200,
            body: { data: [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'does not attempt to upsert accommodations' do
        expect(Accommodation).not_to receive(:upsert)
        service.fetch_and_sync_accommodations
      end
    end

    context 'when API returns error' do
      before do
        stub_request(:get, described_class::BASE_URL)
          .with(query: hash_including(page: '1', per_page: '100'))
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'logs error and does not upsert accommodations' do
        expect(Rails.logger).to receive(:error).with(/Toploc API request failed for page 1/)
        expect(Accommodation).not_to receive(:upsert)

        service.fetch_and_sync_accommodations
      end
    end

    context 'when API times out' do
      before do
        stub_request(:get, described_class::BASE_URL)
          .with(query: hash_including(page: '1', per_page: '100'))
          .to_timeout
      end

      it 'logs error and does not upsert accommodations' do
        expect(Rails.logger).to receive(:error).with(/Error fetching Toploc listings page 1/)
        expect(Accommodation).not_to receive(:upsert)

        service.fetch_and_sync_accommodations
      end
    end
  end

  describe 'pagination handling' do
    it 'fetches multiple pages until empty page' do
      # First page with full results
      stub_request(:get, described_class::BASE_URL)
        .with(query: hash_including(page: '1', per_page: '100'))
        .to_return(
          status: 200,
          body: { data: Array.new(100) { sample_listing } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      # Second page with partial results (less than 100, so it should stop)
      stub_request(:get, described_class::BASE_URL)
        .with(query: hash_including(page: '2', per_page: '100'))
        .to_return(
          status: 200,
          body: { data: Array.new(25) { sample_listing } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(Rails.logger).to receive(:info).with("Fetched 100 listings from Toploc page 1")
      expect(Rails.logger).to receive(:info).with("Fetched 25 listings from Toploc page 2")
      expect(Rails.logger).to receive(:info).with("Synced 100 accommodations from current page")
      expect(Rails.logger).to receive(:info).with("Synced 25 accommodations from current page")
      expect(Rails.logger).to receive(:info).with("Total synced: 125 accommodations from Toploc")
      
      allow(Accommodation).to receive(:upsert)
      service.fetch_and_sync_accommodations
    end
  end

  describe 'data transformation' do
    let(:invalid_listing) do
      {
        "id" => "invalid",
        "attributes" => {
          "title" => nil,
          "lng" => nil,
          "lat" => nil
        }
      }
    end

    before do
      stub_request(:get, described_class::BASE_URL)
        .with(query: hash_including(page: '1', per_page: '100'))
        .to_return(
          status: 200,
          body: { data: [sample_listing, invalid_listing] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      
      stub_request(:get, described_class::BASE_URL)
        .with(query: hash_including(page: '2', per_page: '100'))
        .to_return(
          status: 200,
          body: { data: [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'filters out invalid listings' do
      expect(Accommodation).to receive(:upsert).with(
        hash_including(external_id: '1951'),
        any_args
      )

      service.fetch_and_sync_accommodations
    end

    it 'transforms valid listings correctly' do
      expected_data = hash_including(
        source: 'toploc',
        external_id: '1951',
        name: 'La mer est belle',
        accommodation_type: 'GITE',
        coordinates: 'POINT(-3.16727 47.618912)',
        city: 'Erdeven',
        zip_code: '56410',
        price: BigDecimal('119.0'),
        url: 'https://toploc.holidu.com//d/51176975',
        images: [
          "https://img.holidu.com/images/5b44d323-9622-4d84-80c4-1fbcb1e763f4/t.jpg",
          "https://img.holidu.com/images/09cef4b6-8265-4989-ab0a-b2bd69c7ec17/t.jpg"
        ]
      )

      expect(Accommodation).to receive(:upsert).with(
        expected_data,
        any_args
      )

      service.fetch_and_sync_accommodations
    end
  end

  describe 'edge cases' do
    context 'with missing price' do
      let(:listing_no_price) do
        listing = sample_listing.deep_dup
        listing["attributes"]["price"] = nil
        listing
      end

      before do
        stub_request(:get, described_class::BASE_URL)
          .with(query: hash_including(page: '1', per_page: '100'))
          .to_return(
            status: 200,
            body: { data: [listing_no_price] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        
        stub_request(:get, described_class::BASE_URL)
          .with(query: hash_including(page: '2', per_page: '100'))
          .to_return(
            status: 200,
            body: { data: [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'handles missing price gracefully' do
        expect(Accommodation).to receive(:upsert).with(
          hash_including(price: nil),
          any_args
        )

        service.fetch_and_sync_accommodations
      end
    end

    context 'with missing images' do
      let(:listing_no_images) do
        listing = sample_listing.deep_dup
        listing["attributes"].delete("images")
        listing
      end

      before do
        stub_request(:get, described_class::BASE_URL)
          .with(query: hash_including(page: '1', per_page: '100'))
          .to_return(
            status: 200,
            body: { data: [listing_no_images] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        
        stub_request(:get, described_class::BASE_URL)
          .with(query: hash_including(page: '2', per_page: '100'))
          .to_return(
            status: 200,
            body: { data: [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'defaults to empty array for images' do
        expect(Accommodation).to receive(:upsert).with(
          hash_including(images: []),
          any_args
        )

        service.fetch_and_sync_accommodations
      end
    end
  end
end