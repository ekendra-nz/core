class Customer; end # So an AR model doesn't have to be included

require_relative "../../../app/models/customer/form"

describe Customer::Form do

  describe "attributes" do
    let(:customer) { double("customer") }
    let(:form)     { Customer::Form.new(customer: customer) }

    it "has a customer" do
      expect(form.customer).to eq(customer)
    end
  end

  describe "delegated attributes to customer" do
    let(:customer) { double("customer") }
    let(:form)     { Customer::Form.new(customer: customer) }

    it "calls customer id" do
      customer.should_receive(:id)
      form.id
    end

    it "calls customer address" do
      customer.should_receive(:address)
      form.address
    end

    it "calls customer distributor" do
      customer.should_receive(:distributor)
      form.distributor
    end
  end

  it "considers the data already persisted as these are update form models" do
    form = Customer::Form.new
    expect(form.persisted?).to be_true
  end

end
