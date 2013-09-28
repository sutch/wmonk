class Exchange < ActiveRecord::Base
  validates_presence_of :url

  belongs_to :url
  belongs_to :content_item
  has_one :body, through: :content_item
  has_one :content_type, through: :content_item

  #
  # Array of distinct URLs from the exchange (response obtained from URL)
  #
  def links
    urls = []
    url = self.url
    return urls if self.content_item.nil?
    self.content_item.parse_for_links.each do |u|
      abs = to_absolute(u) rescue next
      urls << abs
    end
    urls.uniq
  end

  def in_domain?(uri)
    uri.host == URI(self.url.value).host
  end

  def to_absolute(link)
    return nil if link.nil?
    link = URI.encode(URI.decode(link.to_s.sub(/(#.*$)/,''))) rescue nil  # remove anchor
    return nil if link.nil?
    relative = URI(link)
    absolute = base ? base.merge(relative) : URI(self.url.value).merge(relative)
    absolute.path = '/' if absolute.path.empty?
    return absolute
  end


  #
  # Base URI from the response
  #
  def base
    return nil if self.content_item.nil?

    return @base if @parsed_for_base

    b = ContentUrls.base_url(self.content_item.body.value, self.content_item.content_type.value)
    @parsed_for_base = true

    return @base if b.nil?

    b = URI(b) rescue nil
    @base = b unless b.to_s.empty?

    @base
  end

end
