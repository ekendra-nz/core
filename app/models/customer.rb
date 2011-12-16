class Customer < ActiveRecord::Base
  include PgSearch

  has_one :address, :dependent => :destroy, :inverse_of => :customer

  has_many :accounts, :dependent => :destroy
  has_many :orders,   :dependent => :destroy
  has_many :payments, :dependent => :destroy

  belongs_to :distributor

  pg_search_scope :search, 
    :against => [:first_name, :last_name, :email, :number], 
    :associated_against => {
      :address => [:address_1, :address_2, :suburb, :city, :postcode, :delivery_note]
    },
    :using => {
      :tsearch => {:prefix => true}
    }
  
  before_create :initialize_number

  accepts_nested_attributes_for :address

  attr_accessible :address_attributes, :first_name, :last_name, :email, :phone, :name, :distributor_id, :distributor

  validates_presence_of :first_name, :last_name, :email, :distributor_id
  validates_uniqueness_of :email, :scope => :distributor_id
  validates_uniqueness_of :number, :scope => :distributor_id

  def name
    "#{first_name} #{last_name}".strip
  end

  def name=(name)
    self.first_name, self.last_name = name.split(" ")
  end

  private
  def initialize_number
    if self.number.nil?
      number = rand(1000000)
      safety = 1
      while(self.distributor.customers.find_by_number(number.to_s).present? && safety < 100) do
        number += 1
        safety += 1
        number = rand(1000000) if safety.modulo(10) == 0
      end
      if safety > 99
        throw "unable to assign customer number"
      end
      self.number = number.to_s
    end
  end
end
