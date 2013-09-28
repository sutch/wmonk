class ContentType < ActiveRecord::Base
  validates_presence_of :value

  has_many :content_items
end