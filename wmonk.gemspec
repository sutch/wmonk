# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','wmonk','version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'wmonk'
  s.version = Wmonk::VERSION
  s.author = 'Dennis Sutch'
  s.email = 'dennis@sutch.com'
  s.homepage = 'http://dennis.sutch.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Web Monk (wmonk) is a command line application for making functional copies of websites.'
# Add your other files here if you make them
  s.files = %w(
bin/wmonk
lib/wmonk/version.rb
lib/wmonk.rb
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','wmonk.rdoc']
  s.rdoc_options << '--title' << 'wmonk' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'wmonk'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_runtime_dependency('gli','2.1.0')
end
