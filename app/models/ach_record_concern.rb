require 'active_support/concern'

module AchRecordConcern
  extend ActiveSupport::Concern

  included do
    include Mongoid::Document

    field :routing_number, type: String
    field :account_number, type: String
    field :bank_name, type: String

    validates_uniqueness_of :routing_number
    validates_presence_of :routing_number, :bank_name
    validates :routing_number, length: { is: ROUTING_NUMBER_LENGTH }
    validates_confirmation_of :routing_number
  end

  class_methods do
    ROUTING_NUMBER_LENGTH = 9
  end
end
