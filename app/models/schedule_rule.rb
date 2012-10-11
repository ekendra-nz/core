class ScheduleRule < ActiveRecord::Base
  attr_accessible :fri, :mon, :month_day, :recur, :sat, :start, :sun, :thu, :tue, :wed, :order_id
  attr_accessor :next_occurrence

  DAYS = [:sun, :mon, :tue, :wed, :thu, :fri, :sat] #Order of this is important, it matches sunday: 0, monday: 1 as is standard
  RECUR = [:one_off, :weekly, :fortnightly, :monthly]

  belongs_to :scheduleable, polymorphic: true, inverse_of: :schedule_rule
  belongs_to :schedule_pause, dependent: :destroy

  scope :with_next_occurrence, (lambda do |date|
    select("schedule_rules.*, next_occurrence('#{date.to_s(:db)}', schedule_rules.*) as next_occurrence")
  end)

  before_save :notify_associations
  after_save :record_schedule_transaction, if: :changed?
  
  DAYS.each do |day|
    default_value_for day, false
  end
  default_value_for :start do
    Date.current
  end

  def self.one_off(datetime)
    ScheduleRule.new(start: datetime)
  end

  def self.recur_on(start, days, recur)
    days &= DAYS #whitelist
    days = days.inject({}){|h, i| h.merge(i => true)} #Turn array into hash
    days = DAYS.inject({}){|h, i| h.merge(i => false)}.merge(days) # Fill out the rest with false

    throw "recur '#{recur}' is :weekly or :fortnightly" unless [:weekly, :fortnightly, :monthly].include?(recur)
    
    if start
      ScheduleRule.new(days.merge(recur: recur, start: start))
    else
      ScheduleRule.new(days.merge(recur: recur))
    end
  end

  def self.weekly(start=nil, days=[])
    recur_on(start, days, :weekly)
  end

  def self.fortnightly(start, days)
    recur_on(start, days, :fortnightly)
  end

  def self.monthly(start, days)
    recur_on(start, days, :monthly)
  end

  def pause(start, finish)
    unless schedule_pause.blank?
      raise "Please unpause before calling pause"
    else
      pause!(start, finish)
    end
  end
  
  def pause!(start, finish)
    self.schedule_pause = SchedulePause.create(start: start, finish: finish)
    save!
  end

  def recur
    r = read_attribute(:recur)
    if r.nil?
      :one_off
    else
      r.to_sym
    end
  end

  def occurs_on?(datetime)
    case recur
    when :one_off
      start == datetime
    when :weekly
      weekly_occurs_on?(datetime)
    when :fortnightly
      fortnightly_occurs_on?(datetime)
    when :monthly
      monthly_occurs_on?(datetime)
    end
  end

  def weekly_occurs_on?(datetime)
    day = datetime.strftime("%a").downcase.to_sym
    self.send("#{day}?") && start<= datetime
  end

  def fortnightly_occurs_on?(datetime)
    # So, theory is, the difference between the start and the date in question as days, divided by 7 should give the number of weeks since the start.  If the number is even, we are on a fortnightly.
    first_occurence = start - start.wday
    weekly_occurs_on?(datetime) && ((datetime - first_occurence) / 7).to_i.even? # 7 days in a week
  end

  def monthly_occurs_on?(datetime)
    weekly_occurs_on?(datetime) && datetime.day < 8
  end

  def next_occurrence(date=nil)
    date ||= Date.current
    occurrence = ScheduleRule.where(id:self.id).with_next_occurrence(date).first.attributes["next_occurrence"] unless new_record?
    
    if occurrence.nil?
      nil
    else
      Date.parse occurrence
    end
  end

  def on_day?(day)
    raise "#{day} is not a valid day" unless DAYS.include?(day)
    if one_off?
      day == DAYS[start.wday]
    else
      self.send(day)
    end
  end

  def one_off?; recur == :one_off;end
  def weekly?; recur == :weekly;end
  def fortnightly?; recur == :fortnightly;end
  def monthly?; recur == :monthly;end

  def days
    DAYS.select{|d| on_day?(d)}
  end

  # returns true if the given schedule_rule occurs on a subset of this schedule_rule's occurrences
  # Only tests pauses in a basic manner, so might return false negatives
  def includes?(schedule_rule)
    raise "Expecting a ScheduleRule, not #{schedule_rule.class}" unless schedule_rule.is_a?(ScheduleRule)
    case recur
    when :one_off
      return false if !schedule_rule.one_off?
    when :fortnightly
      return false if schedule_rule.weekly? || schedule_rule.monthly?
      if schedule_rule.fortnightly?
        return false if !((schedule_rule.start - (start - start.wday)) / 7).to_i.even?
      end
    when :monthly
      return false unless schedule_rule.monthly? || (schedule_rule.one_off? && schedule_rule.start.day < 8)
    else
      true
    end

    too_soon = start > schedule_rule.start
    return false if too_soon

    if schedule_pause
      return false unless ((schedule_rule.one_off? && 
          schedule_rule.start < schedule_pause.start) || 
        schedule_pause.finish <= schedule_rule.start) ||
      schedule_pause.finish <= schedule_rule.start
    else
    end
    
    schedule_rule.days.all?{|day| on_day?(day)}
  end

  def has_at_least_one_day?
    DAYS.collect{|day| self.send(day)}.any?
  end

  def json
    to_json(include: :schedule_pause)
  end

  def notify_associations
    scheduleable.schedule_changed(self) if changed? && scheduleable.present?
  end

  def record_schedule_transaction
    ScheduleTransaction.create!(schedule_rule: json, schedule_rule_id: self.id)
  end

  def deleted_days
    DAYS.select{|day| self.send("#{day.to_s}_changed?".to_sym) && self.send(day) == false}
  end

  def deleted_day_numbers
    DAYS.each_with_index.collect{|day, index| (self.send("#{day.to_s}_changed?".to_sym) && self.send(day) == false) ? index : nil}.compact
  end

  def pause(start, finish=nil)
    return false if start_date.past? || end_date.past? || (end_date < start_date)

    self.schedule_pause = SchedulePause.create!(start: start, finish: finish)
  end

  def self.generate_data(count)
    count.times do
      days = DAYS.shuffle[0..(rand(7))]
      start= Date.today - 700.days + (rand(1400).days)
      recur = [:one_off, :weekly, :fortnightly, :monthly].shuffle.first
      case recur
      when :one_off
        ScheduleRule.one_off(start)
      when :weekly
        ScheduleRule.weekly(start, days)
      when :fortnightly
        ScheduleRule.fortnightly(start, days)
      when :monthly
        ScheduleRule.monthly(start, days)
      end.save
    end
  end

  def self.copy_orders_schedule(o)
    s = ice_cube(o.schedule)
    s.order = o

    unless o.schedule.extimes.empty?
      sp = SchedulePause.from_ice_cube(o.schedule) 
      sp.save!
      s.schedule_pause = sp
    end
    s
  end

  def self.ice_cube(schedule)
    start = schedule.start_time.to_date
    days = schedule.recurrence_days.map{|d| Date::DAYNAMES[d][0..2].downcase.to_sym}

    case schedule.frequency.to_s
    when 'single'
      ScheduleRule.one_off(start)
    when 'weekly'
      ScheduleRule.weekly(start, days)
    when 'fortnightly'
      ScheduleRule.fortnightly(start, days)
    when 'monthly'
      days = schedule.rrules.first.to_hash[:validations][:day_of_week].collect(&:first).map{|d| Date::DAYNAMES[d][0..2].downcase.to_sym}
      ScheduleRule.monthly(start, days)
    end
  end

  def self.copy_from_ice
    Distributor.all.each do |d|
      Time.zone = d.time_zone
      d.orders.all.each do |o|
        begin
          s = copy_orders_schedule(o)
          s.save!
        rescue => e
          puts e
        end
      end
    end
  end
end
