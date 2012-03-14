require 'spec_helper'

describe Distributor do
  context :initialize do
    before(:all) { @distributor = Fabricate(:distributor, :email => ' BuckyBox@example.com ') }

    specify { @distributor.should be_valid }
    specify { @distributor.parameter_name.should == @distributor.name.parameterize }
    specify { @distributor.email.should == 'buckybox@example.com' }
    specify { @distributor.advance_hour.should == 18 }
    specify { @distributor.advance_days.should == 3 }
    specify { @distributor.automatic_delivery_hour.should == 18 }
  end

  context 'delivery window parameters' do
    specify { Fabricate.build(:distributor, advance_hour: -1).should_not be_valid }
    specify { Fabricate.build(:distributor, advance_days: 0).should_not be_valid }
    specify { Fabricate.build(:distributor, automatic_delivery_hour: -1).should_not be_valid }
  end

  context 'support email' do
    specify { Fabricate(:distributor, email: 'buckybox@example.com').support_email.should == 'buckybox@example.com' }
    specify { Fabricate(:distributor, support_email: 'support@example.com').support_email.should == 'support@example.com' }
  end

  context 'cron related methods' do
    before do
      @distributor = Fabricate(:distributor)
      daily_orders(@distributor)
    end

    specify { @distributor.should be_valid }

    after { Delorean.back_to_the_present }

    context 'for instance' do
      before do
        @current_date = Date.parse('2012-03-20')
        Delorean.time_travel_to(@current_date)
      end

      context '#create_daily_lists' do
        context 'with default date' do
          specify { expect { @distributor.create_daily_lists }.should change(@distributor.packing_lists, :count).by(1) }
          specify { expect { @distributor.create_daily_lists }.should change(@distributor.delivery_lists, :count).by(1) }

          context 'lists should have the correct dates' do
            before { @distributor.create_daily_lists }

            specify { PackingList.find_by_distributor_id_and_date(@distributor.id, @current_date.to_date).should_not be_nil }
            specify { DeliveryList.find_by_distributor_id_and_date(@distributor.id, @current_date.to_date).should_not be_nil }
          end
        end

        context 'specifying the date' do
          before { @specified_date = @current_date + 3.days }

          specify { expect { @distributor.create_daily_lists(@specified_date) }.should change(@distributor.packing_lists, :count).by(1) }
          specify { expect { @distributor.create_daily_lists(@specified_date) }.should change(@distributor.delivery_lists, :count).by(1) }

          context 'lists should have the correct dates' do
            before { @distributor.create_daily_lists(@specified_date) }

            specify { PackingList.find_by_distributor_id_and_date(@distributor.id, @specified_date.to_date).should_not be_nil }
            specify { DeliveryList.find_by_distributor_id_and_date(@distributor.id, @specified_date.to_date).should_not be_nil }
          end
        end
      end

      context '#automate_completed_status' do
        context 'with default date' do
          before { @distributor.create_daily_lists(@current_date - 1.day) }

          specify { expect { @distributor.automate_completed_status }.should
                    change(PackingList.find_by_distributor_id_and_date(@distributor.id, @current_date - 1.day).packages.first, :status).from('unpacked').to('packed')
          }
          specify { expect { @distributor.automate_completed_status }.should
                    change(PackingList.find_by_distributor_id_and_date(@distributor.id, @current_date - 1.day).packages.last, :status).from('unpacked').to('packed')
          }
          specify { expect { @distributor.automate_completed_status }.should 
                    change(DeliveryList.find_by_distributor_id_and_date(@distributor.id, @current_date - 1.day).deliveries.first, :status).from('pending').to('delivered')
          }
          specify { expect { @distributor.automate_completed_status }.should 
                    change(DeliveryList.find_by_distributor_id_and_date(@distributor.id, @current_date - 1.day).deliveries.last, :status).from('pending').to('delivered')
          }
        end

        context 'specifying the date' do
          before do 
            @specified_date = @current_date + 3.days
            @distributor.create_daily_lists(@specified_date)
          end

          specify { expect { @distributor.automate_completed_status(@specified_date) }.should
                    change(PackingList.find_by_distributor_id_and_date(@distributor.id, @specified_date).packages.first, :status).from('unpacked').to('packed')
          }
          specify { expect { @distributor.automate_completed_status(@specified_date) }.should
                    change(PackingList.find_by_distributor_id_and_date(@distributor.id, @specified_date).packages.last, :status).from('unpacked').to('packed')
          }
          specify { expect { @distributor.automate_completed_status(@specified_date) }.should 
                    change(DeliveryList.find_by_distributor_id_and_date(@distributor.id, @specified_date).deliveries.first, :status).from('pending').to('delivered')
          }
          specify { expect { @distributor.automate_completed_status(@specified_date) }.should 
                    change(DeliveryList.find_by_distributor_id_and_date(@distributor.id, @specified_date).deliveries.last, :status).from('pending').to('delivered')
          }
        end
      end
    end

    context 'for class' do
      before do
        @current_date = Time.new(2012, 3, 20, 18)
        Delorean.time_travel_to(@current_date)

        @distributor2 = Fabricate(:distributor, advance_hour: 12, advance_days: 4, automatic_delivery_hour: 22)
        daily_orders(@distributor2)
        @distributor3 = Fabricate(:distributor, advance_hour: 0, advance_days: 7, automatic_delivery_hour: 24)
        daily_orders(@distributor3)
      end

      context '#self.create_daily_lists' do
        context '@distributor should generate daily lists' do
          specify { expect { Distributor.create_daily_lists }.should change(PackingList, :count).by(1) }
          specify { expect { Distributor.create_daily_lists }.should change(DeliveryList, :count).by(1) }
        end
      end

      context '#self.automate_completed_status' do
      end
    end
  end

  def daily_orders(distributor)
    daily_order_schedule = schedule = Schedule.new
    daily_order_schedule.add_recurrence_rule(Rule.daily)

    3.times do
      customer = Fabricate(:customer, distributor: distributor)
      Fabricate(:active_order, account: customer.account, schedule: daily_order_schedule)
    end
  end
end
