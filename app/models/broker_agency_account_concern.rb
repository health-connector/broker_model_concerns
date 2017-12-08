require 'active_support/concern'

module BrokerAgencyAccountConcern
  extend ActiveSupport::Concern

  included do
    include Mongoid::Document
    include Mongoid::Timestamps

    # Begin date of relationship
    field :start_on, type: DateTime

    # End date of relationship
    field :end_on, type: DateTime
    field :updated_by, type: String

    # Broker agency representing ER
    field :broker_agency_profile_id, type: BSON::ObjectId

    # Broker writing_agent credited for enrollment and transmitted on 834
    field :writing_agent_id, type: BSON::ObjectId
    field :is_active, type: Boolean, default: true

    validates_presence_of :start_on, :broker_agency_profile_id, :is_active

    default_scope   ->{ where(:is_active => true) }

    def broker_agency_profile=(new_broker_agency_profile)
      pp new_broker_agency_profile if !new_broker_agency_profile.is_a?(BrokerAgencyProfile)
      raise ArgumentError.new("expected BrokerAgencyProfile") unless new_broker_agency_profile.is_a?(BrokerAgencyProfile)
      self.broker_agency_profile_id = new_broker_agency_profile._id
      @broker_agency_profile = new_broker_agency_profile
    end

    def broker_agency_profile
      return @broker_agency_profile if defined? @broker_agency_profile
      @broker_agency_profile = BrokerAgencyProfile.find(self.broker_agency_profile_id) unless self.broker_agency_profile_id.blank?
    end

    def legal_name
      broker_agency_profile.present? ? broker_agency_profile.legal_name : ""
    end

    class << self
      def find(id)
        org = Organization.unscoped.where(:"employer_profile.broker_agency_accounts._id" => id).first
        org.employer_profile.broker_agency_accounts.detect { |account| account._id == id } unless org.blank?
      end
    end
  end

  class_methods do

  end
end
