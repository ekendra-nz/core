require 'spec_helper'

describe 'analytical' do
  before(:each) do
    @box = Fabricate(:box)
    @distributor = @box.distributor
  end

  context "when logged out" do
    it "tracks view distributor sign in form" do
      visit new_distributor_session_path
      page.should have_content('view_distributor_sign_in')
    end

    it "tracks distributor sign in" do
      simulate_distributor_login
      page.should have_content('distributor_signed_in')
    end

    it "tracks view marketplace" do
      visit market_store_path(@distributor.parameter_name)
      page.should have_content('view_store')
      page.should have_content("\"distributor_id\":#{@distributor.id}")
    end

    it "tracks begin order" do
      visit market_store_path(@distributor.parameter_name)
      click_button 'Buy'
      page.should have_content('begin_order')
      page.should have_content("\"distributor_id\":#{@distributor.id}")
    end

    it "tracks complete order" do
      visit market_store_path(@distributor.parameter_name)
      click_button 'Buy'
      fill_in 'Your Email', :with => 'test@enspiral.com'
      fill_in 'Quantity', :with => '1'
      select 'Single', :from => 'Frequency'
      click_button 'Next'
      page.should have_content 'Customer Details'
      fill_in 'First name', :with => 'test'
      fill_in 'Last name', :with => 'test'
      fill_in 'Address 1', :with => 'test'
      fill_in 'Suburb', :with => 'test'
      fill_in 'City', :with => 'test'
      fill_in 'Postcode', :with => 'test'
      click_button 'Next'
      click_button 'Next'
      page.should have_content('complete_order')
      page.should have_content("\"distributor_id\":#{@distributor.id}")
    end

  end

end
