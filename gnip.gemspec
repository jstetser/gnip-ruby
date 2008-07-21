Gem::Specification.new do |s|
  s.name ="gnip"
  s.version = "0.0.4"
  s.homepage = "http://www.gnipcentral.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "Library to access Gnip"
  s.files = Dir.glob("lib/**/*[^~]") 
  s.require_path = "lib"
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
  s.add_dependency("xml-simple", [">= 1.0.11"])
end