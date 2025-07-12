require 'rails_helper'

RSpec.describe Accommodation, type: :model do
  describe 'validations' do
    let(:accommodation) { build(:accommodation) }

    it 'is valid with valid attributes' do
      expect(accommodation).to be_valid
    end

    it 'requires a name' do
      accommodation.name = nil
      expect(accommodation).not_to be_valid
      expect(accommodation.errors[:name]).to include("doit être rempli(e)")
    end

    it 'requires a source' do
      accommodation.source = nil
      expect(accommodation).not_to be_valid
      expect(accommodation.errors[:source]).to include("doit être rempli(e)")
    end

    it 'requires an external_id' do
      accommodation.external_id = nil
      expect(accommodation).not_to be_valid
      expect(accommodation.errors[:external_id]).to include("doit être rempli(e)")
    end

    it 'requires coordinates' do
      accommodation.coordinates = nil
      expect(accommodation).not_to be_valid
      expect(accommodation.errors[:coordinates]).to include("doit être rempli(e)")
    end

    it 'requires unique external_id within the same source' do
      create(:accommodation, source: 'toploc', external_id: '123')
      duplicate = build(:accommodation, source: 'toploc', external_id: '123')
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:external_id]).to include('est déjà utilisé(e)')
    end

    it 'allows same external_id for different sources' do
      create(:accommodation, source: 'toploc', external_id: '123')
      different_source = build(:accommodation, source: 'other_source', external_id: '123')
      
      expect(different_source).to be_valid
    end
  end

  describe 'serialization' do
    it 'serializes images as an array' do
      accommodation = create(:accommodation, images: ['image1.jpg', 'image2.jpg'])
      expect(accommodation.reload.images).to eq(['image1.jpg', 'image2.jpg'])
    end
  end

  describe '#longitude' do
    it 'returns the longitude from coordinates' do
      accommodation = create(:accommodation, 
        coordinates: 'POINT(2.3522 48.8566)')
      expect(accommodation.longitude).to eq(2.3522)
    end

    it 'returns nil when coordinates are nil' do
      accommodation = build(:accommodation, coordinates: nil)
      expect(accommodation.longitude).to be_nil
    end
  end

  describe '#latitude' do
    it 'returns the latitude from coordinates' do
      accommodation = create(:accommodation, 
        coordinates: 'POINT(2.3522 48.8566)')
      expect(accommodation.latitude).to eq(48.8566)
    end

    it 'returns nil when coordinates are nil' do
      accommodation = build(:accommodation, coordinates: nil)
      expect(accommodation.latitude).to be_nil
    end
  end

  describe '.within_bounds' do
    let!(:accommodation_inside) { 
      create(:accommodation, coordinates: 'POINT(2.0 48.0)') 
    }
    let!(:accommodation_outside) { 
      create(:accommodation, coordinates: 'POINT(5.0 50.0)') 
    }

    it 'returns accommodations within the given bounds' do
      bounds = [1.0, 47.0, 3.0, 49.0] # sw_lng, sw_lat, ne_lng, ne_lat
      
      result = Accommodation.within_bounds(bounds)
      
      expect(result).to include(accommodation_inside)
      expect(result).not_to include(accommodation_outside)
    end

    it 'returns empty when no accommodations are within bounds' do
      bounds = [10.0, 10.0, 11.0, 11.0]
      
      result = Accommodation.within_bounds(bounds)
      
      expect(result).to be_empty
    end
  end
end
