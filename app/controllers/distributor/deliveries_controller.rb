#FIXME: Too much code in this controller!

require 'csv'

class Distributor::DeliveriesController < Distributor::ResourceController
  custom_actions collection: [:update_status, :master_packing_sheet, :export]

  respond_to :html, :xml, except: [:update_status, :export]
  respond_to :json, except: [:master_packing_sheet, :export]
  respond_to :csv, only: :export

  def index
    @routes = current_distributor.routes

    if @routes.empty?
      redirect_to distributor_settings_routes_url, alert: 'You must create a route before you can view the deliveries page.' and return
    end

    unless params[:date] && params[:view]
      redirect_to date_distributor_deliveries_url(Date.current, 'packing') and return
    end

    index! do
      @selected_date = Date.parse(params[:date])
      @route_id = params[:view].to_i
      @delivery_list = current_distributor.delivery_lists.where(date: params[:date]).first

      @date_navigation = (nav_start_date..nav_end_date).to_a
      @months = @date_navigation.group_by(&:month)

      if @route_id.zero?
        @packing_list  = PackingList.collect_list(current_distributor, @selected_date)

        @all_packages  = @packing_list.packages

        @items     = @all_packages
        @real_list = @items.all? { |i| i.is_a?(Package) }
        @route     = @routes.first
        @show_tour = current_distributor.deliveries_index_packing_intro
      else
        if @delivery_list
          @all_deliveries = @delivery_list.deliveries.ordered
        else
          @delivery_list = DeliveryList.collect_list(current_distributor, @selected_date)
          @all_deliveries = @delivery_list.deliveries
        end

        @items     = @all_deliveries.select{ |delivery| delivery.route_id == @route_id }
        @real_list = @items.all? { |i| i.is_a?(Delivery) }
        @route     = @routes.find(@route_id)
        @show_tour = current_distributor.deliveries_index_deliveries_intro
      end
    end
  end

  def update_status
    deliveries = current_distributor.deliveries.ordered.where(id: params[:deliveries])
    status = Delivery::STATUS_TO_EVENT[params[:status]]

    options = {}
    options[:date] = params[:date] if params[:date]

    if Delivery.change_statuses(deliveries, status)
      head :ok
    else
      head :bad_request
    end
  end

  def make_payment
    deliveries = current_distributor.deliveries.ordered.where(id: params[:deliveries])
    result = false

    if params[:reverse_payment]
      result = Delivery.reverse_pay_on_delivery(deliveries)
    else
      result = Delivery.pay_on_delivery(deliveries)
    end

    if result
      head :ok
    else
      head :bad_request
    end
  end

  def export
    export = get_export(params)

    if export
      send_data(*export.csv)
    else
      redirect_to :back
    end
  end

  def master_packing_sheet
    redirect_to :back and return unless params[:packages]

    @packages = current_distributor.packages.find(params[:packages])

    @packages.each do |package|
      package.status = 'packed'
      package.packing_method = 'manual'
      package.save!
    end

    @date = @packages.first.packing_list.date

    render layout: 'print'
  end

  def reposition
    delivery_list = current_distributor.delivery_lists.find_by_date(params[:date])

    if delivery_list.reposition(params[:delivery])
      head :ok
    else
      head :bad_request
    end
  end

  def nav_start_date
    Date.current - Order::FORCAST_RANGE_BACK
  end

  def nav_end_date
    Date.current + Order::FORCAST_RANGE_FORWARD
  end

private

  #NOTE: These methods are used to clean up the export input. When the UI gets better we should be able to remove
  # most if not all of the code.
  def get_export(args)
    found_key = find_key(args)
    csv_exporter, ids = make_sales_args(found_key, args[found_key]) if found_key
    csv_exporter.new(current_distributor, ids) if csv_exporter
  end

  def find_key(args)
    found_key = nil
    [:deliveries, :packages, :orders].each { |key| found_key = key if args.has_key?(key) }
    found_key
  end

  def make_sales_args(key, value)
    key = "#{key.to_s.singularize.titleize.constantize}CsvExport"
    key = key.constantize
    [ key, value ]
  end
end
