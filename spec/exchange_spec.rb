require 'rspec'
require File.dirname(__FILE__) + "/spec_helper"

describe Exchange do

  before(:each) do
    path = Dir.mktmpdir
    copy = Wmonk::Copy.new(path)
    copy.create
    @exchange = Exchange.new()
  end

  it "requires a url and status code" do
    subject { @exchange }

    subject.save
    expect(subject.errors[:url].length).not_to eq(0)

    subject.url = Url.create(value: "http://www.example.com/")
    subject.status_code = 200
    subject.anemone_page = 'A Marshaled Anemone::Page object'
    subject.save
    expect(subject.errors[:url].length).to eq 0
  end

end
