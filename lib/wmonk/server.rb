module Wmonk
  class Server

    def initialize(project, options = {})
      @options = {
        :port => 8110,
      }.merge(options)
      @project = project
    end

    def start
      project = @project  # local variable for Sinatra
      my_app = Sinatra.new do
        enable :inline_templates
        get '/' do
          slim :index, :locals => {:project => project, :url => Url, :exchange => Exchange, :content_item => ContentItem}
        end
        get '/urls' do
          slim :urls, :locals => {:url => Url}
        end
        get '/exchanges' do
          slim :exchanges, :locals => {:exchange => Exchange}
        end
        get '/exchange/:encoded_url' do |encoded_url|
          url = Url.find_by_encoded(encoded_url)
          if url.nil?
            'URL not found'
          else
            exchange = url.exchanges.order('created_at DESC').first
            slim :exchange, :locals => {:exchange => exchange}
          end
        end
        get '/copy/:encoded_url' do |encoded_url|
          url = Url.find_by_encoded(encoded_url)
          if url.nil?
            'URL not found'
          else
            exchange = url.exchanges.order('created_at DESC').first
            content_item = exchange.content_item
            if content_item.nil?

            else
              rewritten = ContentUrls.rewrite_each_url(content_item.body.value, content_item.content_type.value) {|u|
                is_valid = true
                begin
                  u = exchange.to_absolute(u)
                rescue
                  is_valid = false
                end
                if is_valid and project.url_in_scope?(u)
                  u = Url.find_by(value: u.to_s)
                  u = "/copy/#{u.encoded.to_s}"
                else
                end
                u
              }
              content_type content_item.content_type.value
              rewritten
            end
          end
        end
        get '/links' do
          slim :links, :locals => {:link => Link}
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
      h1 Wmonk Server
      li
        a href="/" Site Information
      li
        a href="/urls" URLs
      li
        a href="/exchanges" Exchanges
      li
        a href='/links' Links

    == yield

@@index
h2 Site Information
li
  | Location of website copy: #{project.path}
li
  | Root URL(s): #{project.root_urls}
li
  | Number of URLs: #{url.count}
li
  | Number of exchanges: #{exchange.count}
li
  | Number of content items: #{content_item.count}



@@urls
h2 URLs
p
  Each URL with information about last exchange (request/response)
table[border='1' cellspacing=0]
  - url.includes(:exchanges).order(:value).each do |u|
    tr
      td.source
        a href ="#{u.value}" source
      td.cached
        - if u.exchanges.count > 0
          a href ="/copy/#{u.encoded}" copy
      td.info
        - if u.exchanges.count > 0
          a href ="/exchange/#{u.encoded}" info
      td.status_code
        - if u.exchanges.count > 0
          #{u.exchanges.order('created_at').last.status_code}
      td.url
        #{u.value}
      td.exchange_count
        #{u.exchanges.count}


@@exchanges
h2 Exchanges
table[border='1' cellspacing=0]
  - exchange.includes(:url).each do |e|
    tr
      td.url
        #{e.url.value}
      td.retrieved
        #{e.created_at}
      td.status_code
        #{e.status_code}


@@exchange
h2 Exchange
li
  | URL: #{exchange.url.value}
li
  | retrieved: #{exchange.created_at}
li
  | status code: #{exchange.status_code}
- if !exchange.content_item.nil?
  li
    | content type: #{exchange.content_item.content_type.value}
li
  a href ="/copy/#{exchange.url.encoded}" copy
li
  | AnemonePage:
blockquote
  pre
    #{Marshal.load(exchange.anemone_page).to_yaml}


@@links
h2 Links
table[border='1' cellspacing=0]
  - link.includes(:content_item).each do |l|
    tr
      td.link
        #{l.value}
      td.content_type
        #{l.content_item.content_type.value}
      td.urls
        - l.content_item.exchanges.each do |e|
          li
            | #{e.url.value}
