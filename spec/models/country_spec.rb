require 'spec_helper'

describe Country do

  context "NZ" do
    before do
      Fabricate(:country, alpha2: "NZ")
      @country = Country.find_by_alpha2 "NZ"
    end

    describe "#name" do
      it "returns New Zealand" do
        @country.name.should eq "New Zealand"
      end
    end

    describe "#full_name" do
      it "aliases #name" do
        @country.full_name.should eq @country.name
      end
    end

    describe "#currency" do
      it "returns NZD" do
        @country.currency.should eq "NZD"
      end
    end

    describe "#time_zone" do
      it "returns Pacific/Auckland" do
        @country.time_zone.should eq "Pacific/Auckland"
      end
    end
  end
end

