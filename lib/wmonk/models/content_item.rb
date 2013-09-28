class ContentItem < ActiveRecord::Base
  validates_presence_of :body
  validates_presence_of :content_type

  has_many :exchanges
  belongs_to :body
  belongs_to :content_type
  has_many :links

  #
  # Array of distinct URLs from the content item (the body when evaluated as the content type)
  #
  def parse_for_links
    return self.links if self.is_parsed
    ContentUrls.urls(self.body.value, self.content_type.value).each do |u|
      next if u.nil? or u.empty?
      self.links.find_or_create_by!(value: u.to_s)
    end
    self.is_parsed = 't'
    self.save!
    return self.links.map {|link| link.value}
  end

end
