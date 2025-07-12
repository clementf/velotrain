require 'rails_helper'

RSpec.describe Api::AccommodationsController, type: :controller do
  describe 'GET #index' do
    let!(:accommodation_inside) { 
      create(:accommodation, 
        name: 'Inside Accommodation',
        coordinates: 'POINT(2.0 48.0)') 
    }
    let!(:accommodation_outside) { 
      create(:accommodation, 
        name: 'Outside Accommodation',
        coordinates: 'POINT(5.0 50.0)') 
    }

    context 'with valid bounds parameter' do
      let(:bounds) { '1.0,47.0,3.0,49.0' } # sw_lng,sw_lat,ne_lng,ne_lat

      it 'returns accommodations within bounds as GeoJSON' do
        get :index, params: { bounds: bounds }

        expect(response).to have_http_status(:success)
        
        json_response = JSON.parse(response.body)
        
        expect(json_response['type']).to eq('FeatureCollection')
        expect(json_response['features']).to be_an(Array)
        expect(json_response['features'].length).to eq(1)
        
        feature = json_response['features'].first
        expect(feature['type']).to eq('Feature')
        expect(feature['geometry']['type']).to eq('Point')
        expect(feature['properties']['name']).to eq('Inside Accommodation')
        expect(feature['properties']['id']).to eq(accommodation_inside.id)
      end

      it 'includes all expected properties' do
        get :index, params: { bounds: bounds }

        json_response = JSON.parse(response.body)
        properties = json_response['features'].first['properties']

        expect(properties).to include(
          'id' => accommodation_inside.id,
          'name' => accommodation_inside.name,
          'accommodation_type' => accommodation_inside.accommodation_type,
          'city' => accommodation_inside.city,
          'zip_code' => accommodation_inside.zip_code,
          'price' => accommodation_inside.price.to_s,
          'url' => accommodation_inside.url,
          'images' => accommodation_inside.images,
          'source' => accommodation_inside.source
        )
      end

      it 'does not include accommodations outside bounds' do
        get :index, params: { bounds: bounds }

        json_response = JSON.parse(response.body)
        accommodation_names = json_response['features'].map { |f| f['properties']['name'] }

        expect(accommodation_names).to include('Inside Accommodation')
        expect(accommodation_names).not_to include('Outside Accommodation')
      end
    end

    context 'with no accommodations in bounds' do
      let(:bounds) { '10.0,10.0,11.0,11.0' }

      it 'returns empty feature collection' do
        get :index, params: { bounds: bounds }

        expect(response).to have_http_status(:success)
        
        json_response = JSON.parse(response.body)
        
        expect(json_response['type']).to eq('FeatureCollection')
        expect(json_response['features']).to be_empty
      end
    end

    context 'with missing bounds parameter' do
      it 'returns bad request error' do
        get :index

        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('bounds parameter is required')
      end
    end

    context 'with empty bounds parameter' do
      it 'returns bad request error' do
        get :index, params: { bounds: '' }

        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('bounds parameter is required')
      end
    end

    context 'with invalid bounds format' do
      it 'returns bad request error for non-numeric values' do
        get :index, params: { bounds: 'invalid,bounds,format,here' }

        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('bounds parameter is required')
      end

      it 'returns bad request error for insufficient coordinates' do
        get :index, params: { bounds: '1.0,2.0,3.0' }

        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('bounds parameter is required')
      end

      it 'returns bad request error for too many coordinates' do
        get :index, params: { bounds: '1.0,2.0,3.0,4.0,5.0' }

        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('bounds parameter is required')
      end
    end

    context 'with multiple accommodations in bounds' do
      let!(:accommodation_2) { 
        create(:accommodation, 
          name: 'Second Accommodation',
          coordinates: 'POINT(2.5 48.5)') 
      }
      let(:bounds) { '1.0,47.0,3.0,49.0' }

      it 'returns all accommodations within bounds' do
        get :index, params: { bounds: bounds }

        json_response = JSON.parse(response.body)
        
        expect(json_response['features'].length).to eq(2)
        
        names = json_response['features'].map { |f| f['properties']['name'] }
        expect(names).to include('Inside Accommodation', 'Second Accommodation')
      end
    end

    context 'with accommodations at boundary edges' do
      let!(:accommodation_inside_edge) { 
        create(:accommodation, 
          name: 'Edge Accommodation',
          coordinates: 'POINT(2.9 48.9)') # Just inside the boundary
      }
      let(:bounds) { '1.0,47.0,3.0,49.0' }

      it 'includes accommodations just inside the boundary' do
        get :index, params: { bounds: bounds }

        json_response = JSON.parse(response.body)
        names = json_response['features'].map { |f| f['properties']['name'] }
        
        expect(names).to include('Edge Accommodation')
      end
    end
  end
end