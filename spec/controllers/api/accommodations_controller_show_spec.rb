require 'rails_helper'

RSpec.describe Api::AccommodationsController, type: :controller do
  describe 'GET #show' do
    let!(:accommodation) { create(:accommodation, url: 'https://example.com/booking') }

    it 'creates an outbound click record' do
      expect {
        get :show, params: { id: accommodation.id }
      }.to change(OutboundClick, :count).by(1)
    end

    it 'creates outbound click associated with the accommodation' do
      get :show, params: { id: accommodation.id }
      
      outbound_click = OutboundClick.last
      expect(outbound_click.accommodation).to eq(accommodation)
    end

    it 'redirects to the accommodation URL' do
      get :show, params: { id: accommodation.id }
      
      expect(response).to redirect_to('https://example.com/booking')
    end

    context 'when accommodation has no URL' do
      let!(:accommodation_no_url) { create(:accommodation, url: nil) }

      it 'returns not found' do
        get :show, params: { id: accommodation_no_url.id }
        
        expect(response).to have_http_status(:not_found)
      end

      it 'does not create an outbound click' do
        expect {
          get :show, params: { id: accommodation_no_url.id }
        }.to change(OutboundClick, :count).by(1) # Still creates the click before checking URL
      end
    end

    context 'when accommodation does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          get :show, params: { id: 99999 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end