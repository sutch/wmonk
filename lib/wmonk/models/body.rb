class Body < ActiveRecord::Base
  validates_presence_of :value
  validates_presence_of :digest

  has_many :content_items
end