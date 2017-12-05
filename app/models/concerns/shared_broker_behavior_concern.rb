require 'active_support/concern'

module SharedBrokerBehaviorConcern
  extend ActiveSupport::Concern

  included do |base|
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    
    base::MARKET_KINDS = MARKET_KINDS
    base::ALL_MARKET_KINDS_OPTIONS = ALL_MARKET_KINDS_OPTIONS
    base::MARKET_KIND_OPTIONS = MARKET_KINDS_OPTIONS
    
    embedded_in :organization
    
    delegate :hbx_id, to: :organization, allow_nil: true
    delegate :legal_name, :legal_name=, to: :organization, allow_nil: false
    delegate :dba, :dba=, to: :organization, allow_nil: true
    delegate :home_page, :home_page=, to: :organization, allow_nil: true
    delegate :fein, :fein=, to: :organization, allow_nil: false
    delegate :is_fake_fein, :is_fake_fein=, to: :organization, allow_nil: false
    delegate :is_active, :is_active=, to: :organization, allow_nil: false
    delegate :updated_by, :updated_by=, to: :organization, allow_nil: false
    
    embeds_one  :inbox, as: :recipient, cascade_callbacks: true
    accepts_nested_attributes_for :inbox
    embeds_many :documents, as: :documentable

    field :entity_kind, type: String
    field :market_kind, type: String
    field :corporate_npn, type: String
    
    validates_presence_of :market_kind, :entity_kind
    
    validates :corporate_npn,
      numericality: {only_integer: true},
      length: { minimum: 1, maximum: 10 },
      uniqueness: true,
      allow_blank: true
    
    validates :market_kind,
      inclusion: { in: -> (val) { base::MARKET_KINDS }, message: "%{value} is not a valid market kind" },
      allow_blank: false

    validates :entity_kind,
      inclusion: { in: Organization::ENTITY_KINDS[0..3], message: "%{value} is not a valid business entity kind" },
      allow_blank: false
      
    field :aasm_state, type: String, default: 'is_applicant'
    field :aasm_state_set_on, type: Date
    
    scope :active,      ->{ any_in(aasm_state: ["is_applicant", "is_approved"]) }
    scope :inactive,    ->{ any_in(aasm_state: ["is_rejected", "is_suspended", "is_closed"]) }

    aasm do
      state :is_applicant, initial: true
      state :is_approved
      state :is_rejected
      state :is_suspended
      state :is_closed

      event :approve do
        transitions from: [:is_applicant, :is_suspended], to: :is_approved
      end

      event :reject do
        transitions from: :is_applicant, to: :is_rejected
      end

      event :suspend do
        transitions from: [:is_applicant, :is_approved], to: :is_suspended
      end

      event :close do
        transitions from: [:is_approved, :is_suspended], to: :is_closed
      end
    end
  end
  
  class_methods do
    extend ConfigAcaBrokerConcern

    MARKET_KINDS = individual_market_is_enabled? ? %W[individual shop both] : %W[shop]

    ALL_MARKET_KINDS_OPTIONS = {
      "Individual & Family Marketplace ONLY" => "individual",
      "Small Business Marketplace ONLY" => "shop",
      "Both - Individual & Family AND Small Business Marketplaces" => "both"
    }
    MARKET_KINDS_OPTIONS = ALL_MARKET_KINDS_OPTIONS.select { |k,v| MARKET_KINDS.include? v }
  end
  
  def market_kind=(new_market_kind)
    write_attribute(:market_kind, new_market_kind.to_s.downcase)
  end
  
  def languages
    if languages_spoken.any?
      return languages_spoken.map {|lan| LanguageList::LanguageInfo.find(lan).name if LanguageList::LanguageInfo.find(lan)}.compact.join(",")
    end
  end
  
  def current_state
    aasm_state.humanize.titleize
  end

  def applicant?
    aasm_state == "is_applicant"
  end
  
  private
    def build_nested_models
      build_inbox if inbox.nil?
    end  
end
