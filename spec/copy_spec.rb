require 'rspec'
require File.dirname(__FILE__) + "/spec_helper"

describe Wmonk::Copy do

  before(:each) do
    @path = Dir.mktmpdir
    @copy = Wmonk::Copy.new(@path)
    @copy.create
  end

  describe '.new' do

    context "copy with no URLs added" do

      it "has no URLs" do
        @copy.url.count.should == 0
      end
    end

    context "copy with added URL" do
      before(:each) do
        @copy.url.where(url: 'http://www.example.com/').first_or_create!
      end

      it "has one URL" do
        @copy.url.count.should == 1
      end
    end
  end

  context "exchange has a body and a URL" do
    before(:each) do
      @url = @copy.url.where(url: 'http://www.example.com/').first_or_create!
      @body = @copy.body.where(digest: '').first_or_initialize
      @body.body = 'blah blah blah'
      @body.save!
      @exchange = @copy.exchange.where(url: @url).first_or_initialize
      @exchange.status_code = 200
      @exchange.content_type = 'text/html'
      @exchange.body = @body
      @exchange.save!
    end

    it "has an exchange" do
      @exchange.body.should == @body
    end

    it "has a URL" do
      @exchange.url.should == @url
    end

  end

end
