module Wmonk
  class InfoServer

    def initialize(copy, options = {})
      @options = {
        :port => 8110,
      }.merge(options)
      @copy = copy
    end


    def start
      copy = @copy  # local variable for Sinatra
      my_app = Sinatra.new do
        enable :inline_templates
        get '/' do
          slim :index, :locals => {:copy => copy }
        end
        get '/resources' do
          slim :resources, :locals => {:copy => copy }
        end
        get '/resource/:url' do |url|
          record = copy.resource_record_by_url(url)
          if record.nil?
            'Resource not found'
          else
            slim :resource, :locals => {:record => record }
          end
        end
      end
      my_app.run!
    end

  end
end


__END__
@@layout
doctype html
html
  head
    title Wmonk
    meta charset="utf-8"

  body
    header
      h1 Wmonk InfoServer
      li
        a href="/" Site Information
      li
        a href="/resources" Resources

    == yield

@@index
h2 Site Information
li
  | Location of website copy: #{copy.path}
li
  | Base URL: #{copy.base_url}
li
  | Number of resources: #{copy.resource_count}

@@resources
h2 Resources
table[border='1' cellspacing=0]
  - copy.each_resource_record do |r|
    tr
      td.url
        a href="/resource/#{CGI::escape(r[:url])}" #{r[:url]}
      - if r[:code].nil?
        td.status = '--'
      - else
        td.status = r[:code]
      td.content_type = r[:content_type]

@@resource
h2 Resource
li URL: #{record[:url]}
li Response code: #{record[:code]}
li Content type: #{record[:content_type]}
li Is not found: #{record[:is_not_found]}
li Is redirect: #{record[:is_redirect]}
li Redirect to: #{record[:redirect_to]}

- if record[:resource].links.any?
  h3 Links found in resource
  - record[:resource].links.each do |link|
    li #{link}
- else
  h3 No links found in resource
