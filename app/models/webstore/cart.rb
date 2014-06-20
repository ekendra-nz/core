#NOTE: Can be cleaned up with SimpleDelegator or Forwardable in std Ruby lib.

require "draper"
require_relative "../webstore"
require_relative "order"
require_relative "customer"

class Webstore::Cart
  include Draper::Decoratable

  attr_reader :id
  attr_reader :order
  attr_reader :customer
  attr_reader :distributor_id
  attr_reader :real_order_id # from factory
  attr_reader :real_customer_id # from factory

  def self.find(id, persistence_class = Webstore::CartPersistence)
    persistence = persistence_class.find_by(id: id)
    persistence.collected_data if persistence
  end

  def initialize(args = {})
    @id                = args[:id]
    @order             = new_order(args)
    @customer          = new_customer(args)
    @distributor_id    = args.fetch(:distributor_id)
    @persistence_class = args.fetch(:persistence_class, Webstore::CartPersistence)
  end

  def new?
    id.nil?
  end

  def completed?
    @completed
  end

  def ==(comparison_cart)
    if new?
      self.object_id == comparison_cart.object_id
    else
      self.id == comparison_cart.id
    end
  end

  def save
    persistence = find_or_create_persistence
    self.id = persistence.id
    persistence.update_attributes(collected_data: self)
  end

  def add_product(product_id)
    order.add_product(product_id)
  end

  def existing_customer
    customer.existing_customer
  end

  def distributor
    Distributor.find(distributor_id)
  end

  def distributor_parameter_name
    distributor.parameter_name
  end

  def stock_list
    distributor.line_items
  end

  def extras_list
    order.extras_list
  end

  def add_order_information(information)
    order.add_information(information)
  end

  def product
    order.product
  end

  def delivery_service
    customer.delivery_service
  end

  def has_extras?
    order.has_extras?
  end

  def payment_method
    order.payment_method
  end

  def payment_list(payment_options_class = ::PaymentOption)
    payment_options_class.options(distributor)
  end

  def has_payment_options?
    payment_list.present?
  end

  def negative_closing_balance?
    closing_balance.negative?
  end

  def closing_balance
    current_balance - order_price
  end

  def current_balance
    customer.account_balance
  end

  def order_price
    order.total
  end

  def amount_due
    [order_price - current_balance, CrazyMoney.zero].max
  end

  def run_factory(factory_class = Webstore::Factory)
    factory = factory_class.assemble(cart: self)

    @real_order_id = factory.order.id
    @real_customer_id = factory.customer.id
    customer.associate_real_customer(@real_customer_id)
    completed!

    factory.customer.add_activity(:order_create, order: factory.order)
    send_confirmation_email(factory.order) if distributor.email_customer_on_new_webstore_order

    factory
  end

private

  attr_reader :persistence_class
  attr_writer :id

  def new_order(args)
    args = args.fetch(:order, {})
    args = args.merge(cart: self)
    Webstore::Order.new(args)
  end

  def new_customer(args)
    args = args.fetch(:customer, {})
    args = args.merge(cart: self)
    Webstore::Customer.new(args)
  end

  def find_or_create_persistence
    persistence = persistence_class.find_by_id(id)
    persistence = persistence_class.create unless persistence
    persistence
  end

  def completed!
    @completed = true
    save
  end

  def send_confirmation_email(order)
    CustomerMailer.delay(
      priority: Figaro.env.delayed_job_priority_high,
      queue: "#{__FILE__}:#{__LINE__}",
    ).order_confirmation(order)
  end
end
