require 'anemone'
require 'content_urls'

# A replacement for Anemone::Page

class AnemoneResource < Anemone::Page

  #
  # Array of distinct URLs from the resource
  #
  def links
    return @links unless @links.nil?
    @links = []
    ContentUrls.urls(body, content_type).each do |u|
      next if u.nil? or u.empty?
      abs = to_absolute(u) rescue next
      @links << abs if in_domain?(abs)
    end
    @links.uniq!
    @links
  end

  #
  # Base URI from the HTML doc head element
  #
  # Anemone::Base#to_absolute expects an instance of URI or nil
  #
  def base
    return @base unless @body_parsed.nil?
    @body_parsed = true

    base = ContentUrls.urls(body, content_type)
    return @base if base.nil?
    base = URI(base) unless base.nil? rescue nil
    @base = base unless base.to_s.empty?

    @base
  end

end
