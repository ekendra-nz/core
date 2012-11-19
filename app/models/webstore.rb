class Webstore
  attr_reader :controller, :distributor, :order

  def initialize(controller, distributor)
    @controller  = controller
    @distributor = distributor

    @order = WebstoreOrder.find_by_id(webstore_session[:webstore_order_id]) if webstore_session
  end

  def process_params
    webstore_params = @controller.params[:webstore_order]

    start_order(webstore_params[:box_id])              if webstore_params[:box_id]
    customise_order(webstore_params)                   if webstore_params[:customise] || webstore_params[:extras]
    login_customer(webstore_params[:user])             if webstore_params[:user]
    update_delivery_information(webstore_params)       if webstore_params[:route]
    add_address_information(webstore_params[:address]) if webstore_params[:address]
    complete_order                                     if webstore_params[:complete]

    @order.save
  end

  def next_step
    @order.status
  end

  def to_session
    { webstore_order_id: @order.id }
  end

  def webstore_session=(session_hash)
    @controller.session[:webstore] = session_hash
  end

  def webstore_session
    @controller.session[:webstore]
  end

  def current_email=(email)
    webstore_session[:email] = email
  end

  def current_email
    webstore_session[:email] if webstore_session
  end

  private

  def start_order(box_id)
    box = Box.where(id: box_id, distributor_id: @distributor.id).first
    customer = @controller.current_customer

    @order = WebstoreOrder.create(box: box, distributor: @distributor, remote_ip: @controller.request.remote_ip)
    @order.account = customer.account if customer

    if box.customisable?
      @order.customise_step
    else
      if @controller.customer_signed_in?
        @order.delivery_step
      else
        @order.login_step
      end
    end

    self.webstore_session = to_session
  end

  def customise_order(customise)
    customise_params = customise[:customise]
    add_exclusions_to_order(customise_params[:dislikes_input]) if customise_params
    add_substitutes_to_order(customise_params[:likes_input])   if customise_params

    extra_params = customise[:extras]
    add_extras_to_order(extra_params) if customise[:extras]

    if !@order.valid?
      @controller.customise_error
    elsif @controller.customer_signed_in? && @controller.current_customer.distributor == @distributor
        @order.delivery_step
    else
      @order.login_step
    end
  end

  def login_customer(user_information)
    email    = user_information[:email]
    password = user_information[:password]
    customer = Customer.find_by_email(email)

    if email.blank?
      @controller.flash[:error] = 'You must provide an email address.'
      @order.login_step
    elsif customer.nil?
      self.current_email = email
      @order.delivery_step
    elsif customer.valid_password?(password) && customer.distributor == @distributor
      @controller.sign_in(customer)
    else
      @controller.flash[:error] = 'You have not provided the correct email address or password for this store. Please try again.'
      @order.login_step
    end
  end

  def update_delivery_information(delivery_information)
    assign_route(delivery_information[:route])                      if delivery_information[:route]
    set_schedule(delivery_information[:schedule_rule])              if delivery_information[:schedule_rule]
    assign_extras_frequency(delivery_information[:extra_frequency]) if delivery_information[:extra_frequency]

    if @controller.flash[:error].blank?
      @order.complete_step
    else
      @order.delivery_step
    end
  end

  def get_customer(options = {})
    return @controller.current_customer if @controller.current_customer

    email = self.current_email

    customer = @order.distributor.customers.new(email: email)
    customer.route = @order.route
    customer.name = options[:name]
    customer.save!

    Event.new_customer_webstore(customer)
    CustomerMailer.login_details(customer).deliver

    @order.account = customer.account
    @order.save

    @controller.sign_in(customer)

    customer
  end

  def add_address_information(address_information)
    customer = get_customer(name: address_information[:name])

    address = customer.address || Address.new(customer: customer)
    address.address_1 = address_information[:street_address]
    address.address_2 = address_information[:street_address_2]
    address.suburb    = address_information[:suburb]
    address.city      = address_information[:city]
    address.postcode  = address_information[:post_code]

    customer.save

    @order.account = customer.account

    @order.placed_step
  end

  def complete_order
    #FIXME: Hack for private launch, crap code, fml
    customer = @order.customer

    if customer
      address = customer.address
      customer_name = customer.first_name
      street_address = address.address_1 if address
    end

    if customer.distributor != @distributor
      @controller.flash[:error] = 'This account does not work for this store. Please log in with the correct user account.'
      @order.login_step
    elsif customer_name.blank? || street_address.blank?
      @controller.flash[:error] = 'Please include a name and street address'
      @order.complete_step
    elsif @order.create_order
      @controller.flash[:notice] = 'Your order has been placed'
      @order.placed_step
    elsif @order.order
      @controller.flash[:error] = 'You have already created this order'
      @order.placed_step
    else
      @controller.flash[:error] = 'There was a problem completing your order'
      @order.complete_step
    end
  end

  def add_exclusions_to_order(exclusions)
    unless exclusions.nil?
      exclusions.delete('')
      @order.exclusions = exclusions
    end
  end

  def add_substitutes_to_order(substitutions)
    unless substitutions.nil?
      substitutions.delete('')
      @order.substitutions = substitutions
    end
  end

  def add_extras_to_order(extras)
    unless extras.nil?
      extras.delete('add_extra')
      @order.extras = extras.select { |k,v| v.to_i > 0 }
    end
  end

  def assign_route(route_information)
    route_id     = route_information[:route]
    @order.route = Route.find(route_id)
  end

  def set_schedule(schedule_information)
    frequency = schedule_information[:frequency]
    start = Date.parse(schedule_information[:start_date])

    if frequency == 'single'
      @order.schedule_rule = ScheduleRule.one_off(start)
    else
      if schedule_information[:days].nil?
        @controller.flash[:error] = 'The schedule requires you select a day of the week.'
      else
        days_by_number = schedule_information[:days].map { |d| ScheduleRule::DAYS[d.first.to_i] }
        @order.schedule_rule = ScheduleRule.recur_on(start, days_by_number, frequency.to_sym)
      end
    end
  end

  def assign_extras_frequency(extra_information)
    extra_frequency = extra_information[:extra_frequency]
    @order.extras_one_off = (extra_frequency == 'true' ? true : false)
  end
end
