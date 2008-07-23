require 'rubygems'
Gem::manage_gems

require 'rake/gempackagetask'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'pathname'

def gem_spec
  eval(File.read(Pathname(__FILE__).dirname + "gnip-ruby.gemspec"))
end


task :default => :spec

Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.need_tar = true
end

desc "Run all specs in spec directory (excluding plugin specs)"
Spec::Rake::SpecTask.new() do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end


