FactoryBot.define do
  factory :accommodation do
    sequence(:name) { |n| "Beautiful Accommodation #{n}" }
    accommodation_type { "GITE" }
    source { "toploc" }
    coordinates { "POINT(2.3522 48.8566)" } # Paris coordinates
    city { "Paris" }
    zip_code { "75001" }
    price { 150.00 }
    url { "https://example.com/accommodation" }
    sequence(:external_id) { |n| "ext_id_#{n}" }
    images { ["https://example.com/image1.jpg", "https://example.com/image2.jpg"] }
  end
end
