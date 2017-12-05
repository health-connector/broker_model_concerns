require 'rails_helper'

RSpec.describe BrokerModelConcerns::Configuration do
  describe "#settings" do
    it "returns a Settings object" do
      expect(BrokerModelConcerns.configuration.settings).to be_kind_of(Config::Options)
    end
  end

end
