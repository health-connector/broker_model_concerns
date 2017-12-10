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

    def primary_broker_role=(new_primary_broker_role = nil)
      if new_primary_broker_role.present?
        raise ArgumentError.new("expected BrokerRole class") unless new_primary_broker_role.is_a? BrokerRole
        self.primary_broker_role_id = new_primary_broker_role._id
      else
        unset("primary_broker_role_id")
      end
      @primary_broker_role = new_primary_broker_role
    end

    def primary_broker_role
      return @primary_broker_role if defined? @primary_broker_role
      @primary_broker_role = BrokerRole.find(self.primary_broker_role_id) unless primary_broker_role_id.blank?
    end

    # has_many active broker_roles
    def active_broker_roles
      # return @active_broker_roles if defined? @active_broker_roles
      @active_broker_roles = BrokerRole.find_active_by_broker_agency_profile(self)
    end

    # alias for broker_roles
    def writing_agents
      active_broker_roles
    end

    # alias for broker_roles - deprecate
    def brokers
      active_broker_roles
    end

    # has_many candidate_broker_roles
    def candidate_broker_roles
      # return @candidate_broker_roles if defined? @candidate_broker_roles
      @candidate_broker_roles = BrokerRole.find_candidates_by_broker_agency_profile(self)
    end

    # has_many inactive_broker_roles
    def inactive_broker_roles
      # return @inactive_broker_roles if defined? @inactive_broker_roles
      @inactive_broker_roles = BrokerRole.find_inactive_by_broker_agency_profile(self)
    end

    def phone
      office = organization.primary_office_location
      office && office.phone.to_s
    end

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
