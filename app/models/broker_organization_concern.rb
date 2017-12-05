require 'active_support/concern'

## Add Broker specific contexts to Organization (defined in Core)
module BrokerOrganizationConcern
  extend ActiveSupport::Concern

  included do
    embeds_one :general_agency_profile, cascade_callbacks: true, validate: true  ##Broker Concern
    embeds_one :broker_agency_profile, cascade_callbacks: true, validate: true  ##Broker Concern

    accepts_nested_attributes_for :general_agency_profile, :broker_agency_profile

    scope :has_general_agency_profile,          ->{ exists(general_agency_profile: true) }
    scope :has_broker_agency_profile,           ->{ exists(broker_agency_profile: true) }

    # BrokerAgencyProfile child model indexes
    index({"broker_agency_profile._id" => 1}, { unique: true, sparse: true })
    index({"broker_agency_profile.aasm_state" => 1})
    index({"broker_agency_profile.primary_broker_role_id" => 1}, { unique: true, sparse: true })
    index({"broker_agency_profile.market_kind" => 1})
  end

  class_methods do
    def search_by_general_agency(search_content)
      Organization.has_general_agency_profile.or({legal_name: /#{search_content}/i}, {"fein" => /#{search_content}/i})
    end

    def build_query_params(search_params)
      query_params = []

      if !search_params[:q].blank?
        q = Regexp.new(Regexp.escape(search_params[:q].strip), true)
        query_params << {"legal_name" => q}
      end

      if !search_params[:languages].blank?
        query_params << {"broker_agency_profile.languages_spoken" => { "$in" => search_params[:languages]} }
      end

      if !search_params[:working_hours].blank?
        query_params << {"broker_agency_profile.working_hours" => eval(search_params[:working_hours])}
      end

      query_params
    end

    def search_agencies_by_criteria(search_params)
      query_params = build_query_params(search_params)
      if query_params.any?
        self.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop']).where({ "$and" => build_query_params(search_params) })
      else
        self.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop'])
      end
    end

    def broker_agencies_with_matching_agency_or_broker(search_params)
      if search_params[:q].present?
        orgs2 = self.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop']).where({
          "broker_agency_profile._id" => {
            "$in" => BrokerRole.agencies_with_matching_broker(search_params[:q])
          }
        })

        brokers = BrokerRole.brokers_matching_search_criteria(search_params[:q])
        if brokers.any?
          search_params.delete(:q)
          if search_params.empty?
            return filter_brokers_by_agencies(orgs2, brokers)
          else
            agencies_matching_advanced_criteria = orgs2.where({ "$and" => build_query_params(search_params) })
            return filter_brokers_by_agencies(agencies_matching_advanced_criteria, brokers)
          end
        end
      end

      self.search_agencies_by_criteria(search_params)
    end

    def filter_brokers_by_agencies(agencies, brokers)
      agency_ids = agencies.map{|org| org.broker_agency_profile.id}
      brokers.select{ |broker| agency_ids.include?(broker.broker_role.broker_agency_profile_id) }
    end
  end
end
