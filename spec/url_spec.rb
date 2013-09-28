require 'rspec'
require File.dirname(__FILE__) + "/spec_helper"

describe Url do

  before(:each) do
    path = Dir.mktmpdir
    @copy = Wmonk::Copy.new(path)
    @copy.create
  end

  it "requires a value" do
    url = Url.new()
    subject { url }

    subject.save
    expect(subject.errors[:value].length).to eq 1

    subject.value = "http://www.example.com/"
    subject.save
    expect(subject.errors[:value].length).to eq 0
  end

end
