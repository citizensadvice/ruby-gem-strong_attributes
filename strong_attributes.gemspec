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
  s.required_ruby_version = ">= 3.0.0"
  s.metadata["rubygems_mfa_required"] = "true"

  s.add_runtime_dependency "activemodel", ">= 6.1.0"
end
