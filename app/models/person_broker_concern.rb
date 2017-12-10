require 'active_support/concern'

module PersonBrokerConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :broker_agency_contact,
                  class_name: "BrokerAgencyProfile",
                  inverse_of: :broker_agency_contacts,
                  index: true

    embeds_one :broker_role, cascade_callbacks: true, validate: true

    accepts_nested_attributes_for :broker_role

    # Broker child model indexes
    index({"broker_role._id" => 1})
    index({"broker_role.provider_kind" => 1})
    index({"broker_role.broker_agency_id" => 1})
    index({"broker_role.npn" => 1}, {sparse: true, unique: true})

    scope :all_broker_roles,            -> { exists(broker_role: true) }
    scope :by_broker_role_npn, ->(br_npn) { where("broker_role.npn" => br_npn) }

    scope :broker_role_having_agency, -> { where("broker_role.broker_agency_profile_id" => { "$ne" => nil }) }
    scope :broker_role_applicant,     -> { where("broker_role.aasm_state" => { "$eq" => :applicant })}
    scope :broker_role_pending,       -> { where("broker_role.aasm_state" => { "$eq" => :broker_agency_pending })}
    scope :broker_role_certified,     -> { where("broker_role.aasm_state" => { "$in" => [:active, :broker_agency_pending]})}
    scope :broker_role_decertified,   -> { where("broker_role.aasm_state" => { "$eq" => :decertified })}
    scope :broker_role_denied,        -> { where("broker_role.aasm_state" => { "$eq" => :denied })}
  end

  class_methods do

  end
end
