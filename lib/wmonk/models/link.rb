class Link < ActiveRecord::Base
  validates_presence_of :value
  validates_presence_of :content_item

  belongs_to :content_item
  has_many :exchanges, through: :content_item
end