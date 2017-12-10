FactoryBot.define do
  factory :broker_agency, class: Organization do
    sequence(:legal_name) {|n| "Broker Agency#{n}" }
    sequence(:dba) {|n| "Broker Agency#{n}" }
    fein do
      Forgery('basic').text(:allow_lower   => false,
                            :allow_upper   => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 9)
    end
    home_page   "http://www.example.com"
    office_locations  { [FactoryBot.build(:office_location, :primary),
                         FactoryBot.build(:office_location)] }

    after(:create) do |organization|
      FactoryBot.create(:broker_agency_profile, organization: organization)
    end

    trait :shop_only do
      after(:create) do |organization|
        FactoryBot.create(:broker_agency_profile, market_kind: "shop", organization: organization)
      end
    end

    trait :ivl_only do
      after(:create) do |organization|
        FactoryBot.create(:broker_agency_profile, market_kind: "individual", organization: organization)
      end
    end

    trait :both_ivl_and_shop do
      after(:create) do |organization|
        FactoryBot.create(:broker_agency_profile, market_kind: "both", organization: organization)
      end
    end
  end
end
