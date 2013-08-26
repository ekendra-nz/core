class OrderPrice
  def self.discounted(price, customer_discount = nil)
    return price if customer_discount.nil? # Convenience so we don't have to check all over app for nil

    customer_discount = customer_discount.discount if customer_discount.is_a?(Customer)
    discounted_price = price * (1 - customer_discount)

    discounted_price.to_money
  end

  def self.individual(box_price, delivery_service_fee, customer_discount = nil)
    box_price = box_price.price if box_price.is_a?(Box)
    delivery_service_fee = delivery_service_fee.fee if delivery_service_fee.is_a?(DeliveryService)
    customer_discount = customer_discount.discount if customer_discount.is_a?(Customer)

    total_price = box_price + delivery_service_fee

    customer_discount ? discounted(total_price, customer_discount) : total_price
  end

  def self.extras_price(order_extras, customer_discount = nil)
    order_extras      = order_extras.map(&:to_hash) unless order_extras.is_a?(Hash)
    customer_discount = customer_discount.discount if customer_discount.is_a?(Customer)

    total_price = order_extras.map do |order_extra|
      money = Money.new(order_extra[:price_cents], order_extra[:currency])
      count = order_extra[:count].to_i
      money * count
    end.sum.to_money

    customer_discount ? discounted(total_price, customer_discount) : total_price
  end

  def self.without_delivery_fee(price, quantity, extras_price, has_extras)
    result = price
    result = result * quantity if quantity
    result += extras_price if has_extras
    result
  end

  def self.with_delivery_fee(price, delivery_fee)
    if delivery_fee && delivery_fee > 0
      price + delivery_fee
    else
      price
    end
  end
end
