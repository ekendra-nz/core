module Distributor::BaseHelper
  def distributor_address(distributor, options = {})
    i = distributor.invoice_information
    join_with = (options[:single_line] ? ', ' : '<br/>')

    address = [i.billing_address_1]
    address << i.billing_address_2 if i.billing_address_2.blank?
    address += [i.billing_suburb, "#{i.billing_city}, #{i.billing_postcode}"]
    address << i.phone_1 if options[:with_phone]

    return address.join(join_with).html_safe
  end

  # force_highlighted = :routes
  # will make the 'Routes' sub_nav title show as highlighted
  def show_settings_sub_nav(force_highlighted = nil)
    content_for :sub_nav do 
      render partial: 'distributor/settings/sub_nav', locals: {force_highlighted: force_highlighted}
    end
  end

  def sub_tab(text, path, opts = {})
    highlighted = current_page?(path) || opts[:force_highlighted].to_s == text.downcase

    content_tag(:dd, class: highlighted ? 'active' : '') do
      link_to text, path
    end
  end
end
