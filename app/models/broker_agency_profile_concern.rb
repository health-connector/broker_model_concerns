require 'active_support/concern'

module BrokerAgencyProfileConcern
  extend ActiveSupport::Concern

  included do
    include SharedBrokerBehaviorConcern

    field :primary_broker_role_id, type: BSON::ObjectId
    field :default_general_agency_profile_id, type: BSON::ObjectId

    field :languages_spoken, type: Array, default: ["en"] # TODO
    field :working_hours, type: Boolean, default: false
    field :accept_new_clients, type: Boolean

    field :ach_routing_number, type: String
    field :ach_account_number, type: String

    class << self
      # TODO; return as chainable Mongoid::Criteria
      def all
        list_embedded Organization.exists(broker_agency_profile: true).order_by([:legal_name]).to_a
      end

      def first
        all.first
      end

      def last
        all.last
      end

      def find(id)
        organizations = Organization.where("broker_agency_profile._id" => BSON::ObjectId.from_string(id)).to_a
        organizations.size > 0 ? organizations.first.broker_agency_profile : nil
      end
    end
  end

  class_methods do
    def list_embedded(parent_list)
      parent_list.reduce([]) { |list, parent_instance| list << parent_instance.broker_agency_profile }
    end
  end

  def default_general_agency_profile=(new_default_general_agency_profile = nil)
    if new_default_general_agency_profile.present?
      raise ArgumentError.new("expected GeneralAgencyProfile class") unless new_default_general_agency_profile.is_a? GeneralAgencyProfile
      self.default_general_agency_profile_id = new_default_general_agency_profile.id
    else
      unset("default_general_agency_profile_id")
    end
    @default_general_agency_profile = new_default_general_agency_profile
  end

  def default_general_agency_profile
    return @default_general_agency_profile if defined? @default_general_agency_profile
    @default_general_agency_profile = GeneralAgencyProfile.find(self.default_general_agency_profile_id) if default_general_agency_profile_id.present?
  end
end
