# frozen_string_literal: true

$LOAD_PATH << File.expand_path("lib", __dir__)
require "strong_attributes/version"

Gem::Specification.new do |s|
  s.name = "strong_attributes"
  s.summary = "Like StrongParameters but with attributes"
  s.version = StrongAttributes::VERSION
  s.files = Dir["lib/**/*.rb"]
  s.authors = ["Daniel Lewis"]
  s.license = "ISC"
  s.required_ruby_version = ">= 3.2"
  s.metadata["rubygems_mfa_required"] = "true"

  s.add_dependency "activemodel", ">= 7.2"
end
