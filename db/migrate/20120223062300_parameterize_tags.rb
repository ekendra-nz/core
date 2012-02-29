class ParameterizeTags < ActiveRecord::Migration
  class ActsAsTaggableOn::Tag < ActiveRecord::Base; end

  def up
    ActsAsTaggableOn::Tag.reset_column_information

    ActsAsTaggableOn::Tag.all.each do |tag|
      value = tag.read_attribute(:name)
      tag.update_attribute(:name, value.parameterize)
    end
  end

  def down
  end
end
