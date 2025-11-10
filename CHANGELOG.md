# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2025-11-10

### Fixed
- RuboCop linting offenses resolved
- Added RubyGems MFA requirement metadata for enhanced security
- Fixed unused block arguments in test files
- Improved code formatting and readability

## [0.1.0] - 2025-11-06

### Added
- Rails generators for easy installation and setup
  - `rails generate rails_mfa:install` - Creates initializer with configuration examples
  - `rails generate rails_mfa:migration User` - Generates migration for MFA columns
- Enhanced documentation with provider-agnostic examples
- Multiple SMS provider examples (Twilio, AWS SNS, Vonage, MessageBird, Plivo)
- Multiple email provider examples (SendGrid, ActionMailer, Postmark)
- Complete authenticator app (TOTP) setup guide with QR code generation
- Dedicated controller examples for authenticator app setup flow
- Improved README emphasizing provider-agnostic nature

### Added
- Initial release of RailsMFA gem
- Support for SMS-based multi-factor authentication
- Support for email-based multi-factor authentication
- Support for TOTP authenticator apps (Google Authenticator, Authy, 1Password, Microsoft Authenticator)
- `RailsMFA::Model` concern for easy integration with any user model
- `RailsMFA::TokenManager` for secure token generation and verification
- `RailsMFA::Configuration` for flexible gem configuration
- Pluggable SMS and email delivery providers via lambdas
- Built-in QR code generation support via `rqrcode` gem
- Timing-safe token comparison using ActiveSupport::SecurityUtils
- One-time use tokens with automatic deletion after verification
- Configurable token expiration (default: 5 minutes)
- Configurable token length (default: 6 digits)
- SimpleStore fallback for applications without Rails.cache
- Provider-agnostic design compatible with Devise, Authlogic, and custom auth systems
- Comprehensive RSpec test suite (52 examples, 0 failures)
- Detailed documentation with integration examples
