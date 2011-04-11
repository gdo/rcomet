require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rcomet"
    gem.summary = %Q{RComet is an implementation of the Bayeux protocol in Ruby.}
    gem.description = %Q{RComet implement the Bayeux protocole to allow you to create client and/or Comet's server.}
    gem.email = "guillaume.dorchies@gmail.com"
    gem.homepage = "http://github.com/glejeune/rcomet"
    gem.authors = ["Guillaume Dorchies", "Gr\303\251goire Lejeune"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_dependency('rack')
    gem.bindir = "bin"
    gem.executables = ["rcomet"]
    gem.rubyforge_project = 'rcomet'
    gem.has_rdoc = true
    gem.extra_rdoc_files = ["README.rdoc", "LICENCE"]
    gem.rdoc_options = ["--title", "RComet", "--main", "README.rdoc", "--line-numbers"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

#require 'spec/rake/spectask'
#Spec::Rake::SpecTask.new(:spec) do |spec|
#  spec.libs << 'lib' << 'spec'
#  spec.spec_files = FileList['spec/**/*_spec.rb']
#end
#
#Spec::Rake::SpecTask.new(:rcov) do |spec|
#  spec.libs << 'lib' << 'spec'
#  spec.pattern = 'spec/**/*_spec.rb'
#  spec.rcov = true
#end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "RComet #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('LICENSE')
  rdoc.rdoc_files.include('History.rdoc')
  rdoc.rdoc_files.include('bin/**/*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
