require 'rspec'
require File.dirname(__FILE__) + "/spec_helper"

describe Wmonk do

  describe '.root_urls' do

    context "no URLs provided" do

      it "has no root URLs" do
        Wmonk.root_urls([]).count.should == 0
      end
    end

    it "has one URL" do
      urls = ['http://www.example.com/']
      Wmonk.root_urls(urls).should == urls
    end

    it "has multiple URLs" do
      urls = ['http://www.example.com/', 'http://www.example.net/', 'http://www.example.org/']
      Wmonk.root_urls(urls).should == urls
    end

    it "has multiple URLs within one site (i.e., one root URL)" do
      urls = ['http://www.example.com/', 'http://www.example.com/?query', 'http://www.example.com/path/index.html']
      Wmonk.root_urls(urls).should == ['http://www.example.com/']
    end

  end

end
