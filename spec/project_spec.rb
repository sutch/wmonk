require 'rspec'
require File.dirname(__FILE__) + "/spec_helper"

describe Wmonk::Project, '#create' do

  before(:each) do
    @dir = Dir.mktmpdir
    @dir_not_empty = Dir.mktmpdir
    File.open(Pathname.new(@dir_not_empty) + "a_file.txt", 'w') {|f| f.write("Test file to make folder non-empty") }
  end

  it 'returns an instance of a new Project in an existing folder' do
    Wmonk::Project.create(@dir).should be_an_instance_of Wmonk::Project
  end

  it 'returns an instance of a new Project in a new folder' do
    dir_project = Pathname.new(@dir) + 'my_project'
    Wmonk::Project.create(dir_project).should be_an_instance_of Wmonk::Project
  end

  it 'creates a configuration file' do
    project = Wmonk::Project.create(@dir)
    File.exist?(Pathname.new(@dir) + 'wmonk.yaml').should == true
  end

  it 'raises an exception when folder is not empty' do
    lambda { Wmonk::Project.create(@dir_not_empty) }.should raise_error
  end

end

describe Wmonk::Project, '#open' do

  before(:each) do
    @dir = Dir.mktmpdir
  end

  it 'reads a Project from aa folder' do
    Wmonk::Project.create(@dir)
    project = Wmonk::Project.open(@dir)
    project.should be_an_instance_of Wmonk::Project
  end

  it 'obtains the title from the configuration file' do
    title = Random.rand.to_s
    Wmonk::Project.create(@dir, title: title)
    project = Wmonk::Project.open(@dir)
    project.title.should == title
  end

  it 'obtains an empty array of root URLs from the configuration file when no root URLs' do
    Wmonk::Project.create(@dir)
    project = Wmonk::Project.open(@dir)
    project.root_urls.size.should == 0
  end

  it 'obtains the list of root URLs from the configuration file' do
    urls = ["http://www.example.com/", "http://www.example.net/"]
    Wmonk::Project.create(@dir, root_urls: urls)
    project = Wmonk::Project.open(@dir)
    project.root_urls.sort.should == urls
  end

  it 'finds URL in scope' do
    urls = ["http://www.example.com/", "http://www.example.net/"]
    Wmonk::Project.create(@dir, root_urls: urls)
    project = Wmonk::Project.open(@dir)
    project.url_in_scope?('http://www.example.com/some/path').should == true
  end

  it 'finds URL is not in scope' do
    urls = ["http://www.example.com/", "http://www.example.net/"]
    Wmonk::Project.create(@dir, root_urls: urls)
    project = Wmonk::Project.open(@dir)
    project.url_in_scope?('http://not.example.com/some/other/path').should == false
  end

  it 'obtains an empty array of seed URLs from the configuration file when no seed URLs' do
    Wmonk::Project.create(@dir)
    project = Wmonk::Project.open(@dir)
    project.seed_urls.size.should == 0
  end

  it 'obtains the list of seed URLs from the configuration file' do
    urls = ["http://www.example.com/", "http://www.example.com/hidden.html"]
    Wmonk::Project.create(@dir, seed_urls: urls)
    project = Wmonk::Project.open(@dir)
    project.seed_urls.sort.should == urls
  end

end