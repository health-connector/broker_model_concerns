require 'active_support/concern'

module GeneralAgencyProfileConcern
  extend ActiveSupport::Concern

  included do
    include SharedBrokerBehaviorConcern
    
    field :languages_spoken, type: Array, default: ["en"] # TODO
    field :working_hours, type: Boolean, default: false
    field :accept_new_clients, type: Boolean
      
    after_initialize :build_nested_models
    
    class << self
      def all
        list_embedded Organization.exists(general_agency_profile: true).order_by([:legal_name]).to_a
      end
      
      def first
        all.first
      end

      def last
        all.last
      end

      def find(id)
        organizations = Organization.where("general_agency_profile._id" => BSON::ObjectId.from_string(id)).to_a
        organizations.size > 0 ? organizations.first.general_agency_profile : nil
      end
    end
  end
    
  class_methods do
    def list_embedded(parent_list)
      parent_list.reduce([]) { |list, parent_instance| list << parent_instance.general_agency_profile }
    end
    
    def filter_by(status="is_applicant")
      if status == 'all'
        all
      else
        list_embedded Organization.exists(general_agency_profile: true).where(:'general_agency_profile.aasm_state' => status).order_by([:legal_name]).to_a
      end
    rescue
      []
    end
  end
end
