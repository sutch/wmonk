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
        get('/') {
          slim :index, :locals => {:copy => copy } }
        get('/resources') {
          slim :resources, :locals => {:copy => copy } }
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
- copy.each_resource do |r|
  li
    | #{r[0]}
    - if r[1].nil?
      |  -- Not yet requested
    - else
      |  [#{r[1]}] #{r[2]}