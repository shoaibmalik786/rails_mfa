# frozen_string_literal: true

require_relative "lib/rails_mfa/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_mfa"
  spec.version       = RailsMFA::VERSION
  spec.authors       = ["Shoaib Malik"]
  spec.email         = ["shoaib2109@gmail.com"]

  spec.summary       = "Add multi-factor authentication (2FA/MFA) to any Rails app with pluggable SMS, Email, and TOTP support."
  spec.description   = "RailsMFA is a provider-agnostic, plug-and-play gem that adds secure multi-factor authentication (MFA/2FA) to any Rails app. Supports SMS, email, and authenticator apps (TOTP) with customizable providers."
  spec.homepage      = "https://github.com/shoaibmalik786/rails_mfa"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"]      = spec.homepage
  spec.metadata["source_code_uri"]   = "https://github.com/shoaibmalik786/rails_mfa"
  spec.metadata["changelog_uri"]     = "https://github.com/shoaibmalik786/rails_mfa/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "activesupport", ">= 6.1"
  spec.add_dependency "rotp", "~> 6.0"
  spec.add_dependency "rqrcode", "~> 2.2"
end
