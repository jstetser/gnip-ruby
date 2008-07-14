require 'rubygems'
Gem::manage_gems

require 'rake/gempackagetask'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/rake/spectask'

task :default => :spec

spec = Gem::Specification.new do |s|
  s.name ="gnip"
  s.version = "0.0.4"
  s.homepage = "http://www.gnipcentral.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "Library to access Gnip"
  s.files = FileList["{lib}/**/*"].to_a
  s.require_path = "lib"
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
  s.add_dependency("xml-simple", ">= 1.0.11")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

desc "Run all specs in spec directory (excluding plugin specs)"
Spec::Rake::SpecTask.new() do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end
