# RailsMFA

A pluggable, provider-agnostic multi-factor authentication (MFA/2FA) gem for Ruby on Rails applications. RailsMFA makes it simple to add secure authentication via SMS, email, or authenticator apps (TOTP) to any Rails application, regardless of your authentication system.

## Features

- **Multiple Authentication Methods**: Support for SMS, email, and TOTP-based authenticator apps (like Google Authenticator, Authy, 1Password, Microsoft Authenticator)
- **Fully Provider Agnostic**: Works with ANY SMS provider (Twilio, AWS SNS, Vonage, MessageBird, etc.) and ANY authentication system (Devise, Authlogic, Clearance, or custom)
- **Pluggable Delivery**: Easy-to-customize SMS and email delivery adapters - bring your own service
- **Secure by Default**: Uses timing-safe comparison and one-time use tokens
- **Flexible Storage**: Works with Rails.cache, Redis, or any custom cache store
- **QR Code Generation**: Built-in support for generating QR codes for authenticator app setup
- **Rails Generators**: Quick setup with `rails generate` commands
- **Simple Configuration**: Minimal setup with sensible defaults

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_mfa'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install rails_mfa
```

## Quick Start

### 1. Run the installer

```bash
rails generate rails_mfa:install
```

This creates an initializer at `config/initializers/rails_mfa.rb` with configuration options.

### 2. Generate the migration

```bash
rails generate rails_mfa:migration User
```

This creates a migration to add MFA columns to your User model (or any model you specify).

### 3. Run the migration

```bash
rails db:migrate
```

**Security Note**: The `mfa_secret` column should be encrypted in production. Use Rails 7's `encrypts` feature or `attr_encrypted`:

```ruby
class User < ApplicationRecord
  encrypts :mfa_secret
end
```

### 4. Include the Model concern in your User model

```ruby
class User < ApplicationRecord
  include RailsMFA::Model

  # Optional: specify which MFA methods this model supports
  enable_mfa_for :sms, :email, :totp
end
```

### 5. Configure Your Providers

Edit `config/initializers/rails_mfa.rb` and configure your preferred SMS and email providers:

```ruby
RailsMFA.configure do |config|
  # Use ANY SMS provider - Twilio, AWS SNS, Vonage, MessageBird, etc.
  # Just provide a lambda that sends the SMS
  config.sms_provider = lambda do |phone_number, message|
    # Your SMS provider implementation here
    # Example: YourSmsService.send(phone_number, message)
  end

  # Use ANY email provider - ActionMailer, SendGrid, Postmark, etc.
  # Just provide a lambda that sends the email
  config.email_provider = lambda do |email, subject, body|
    # Your email provider implementation here
    # Example: YourMailer.send_code(email, subject, body).deliver_now
  end

  # Optional: customize token settings
  config.code_length = 6              # Default: 6 digits
  config.code_expiry_seconds = 300    # Default: 5 minutes

  # Optional: use custom cache store (Redis, Memcached, etc.)
  # config.token_store = Redis.new
end
```

## Usage

### Email-based MFA

```ruby
# Send a verification code
user = User.find(params[:id])
code = user.send_numeric_code(via: :email)

# Verify the code
if user.verify_numeric_code(params[:code])
  # Code is valid and user is authenticated
  session[:mfa_verified] = true
  redirect_to dashboard_path
else
  # Code is invalid
  flash[:error] = "Invalid verification code"
end
```

### SMS-based MFA

```ruby
# Send a verification code
code = user.send_numeric_code(via: :sms)

# Verify the code (same as email)
if user.verify_numeric_code(params[:code])
  session[:mfa_verified] = true
  redirect_to dashboard_path
end
```

### Authenticator App (TOTP) - Google Authenticator, Authy, 1Password, Microsoft Authenticator

Authenticator apps provide the most secure MFA method using time-based one-time passwords (TOTP).

#### Setup Flow

```ruby
# 1. Generate a secret for the user (do this once during setup)
user.generate_totp_secret!

# 2. Get the provisioning URI for QR code generation
provisioning_uri = user.totp_provisioning_uri(issuer: "MyApp")

# 3. Generate QR code for the user to scan
require 'rqrcode'
qrcode = RQRCode::QRCode.new(provisioning_uri)

# For HTML view:
@qr_svg = qrcode.as_svg(
  module_size: 4,
  standalone: true,
  use_path: true
)

# Or for PNG:
@qr_png = qrcode.as_png(size: 300)
```

#### Verification

```ruby
# Verify the TOTP code from the authenticator app
if user.verify_totp(params[:code])
  user.update(mfa_enabled: true, mfa_method: 'totp')
  session[:mfa_verified] = true
  redirect_to dashboard_path
else
  flash[:error] = "Invalid authenticator code"
  render :verify
end
```

#### Example Controller (Complete Setup Flow)

```ruby
# app/controllers/mfa/authenticator_controller.rb
class Mfa::AuthenticatorController < ApplicationController
  before_action :authenticate_user!

  def new
    # Show setup page
  end

  def create
    # Generate secret and show QR code
    current_user.generate_totp_secret!
    provisioning_uri = current_user.totp_provisioning_uri(issuer: "MyApp")
    @qrcode = RQRCode::QRCode.new(provisioning_uri)
  end

  def verify
    # Verify the code from authenticator app
    if current_user.verify_totp(params[:code])
      current_user.update!(mfa_enabled: true, mfa_method: 'totp')
      flash[:success] = "Authenticator app configured successfully!"
      redirect_to profile_path
    else
      flash[:error] = "Invalid code. Please try again."
      redirect_to mfa_authenticator_path
    end
  end
end
```

#### Example View (QR Code Display)

```erb
<!-- app/views/mfa/authenticator/create.html.erb -->
<div class="authenticator-setup">
  <h2>Set Up Authenticator App</h2>

  <p>Scan this QR code with your authenticator app:</p>

  <div class="qr-code">
    <%= @qrcode.as_svg(module_size: 4).html_safe %>
  </div>

  <p>Or enter this secret key manually:</p>
  <code><%= current_user.mfa_secret %></code>

  <p>After scanning, enter the 6-digit code from your app to verify:</p>

  <%= form_with url: verify_mfa_authenticator_path, method: :post do |f| %>
    <%= f.text_field :code, placeholder: "000000", maxlength: 6, autofocus: true %>
    <%= f.submit "Verify and Enable" %>
  <% end %>
</div>
```

## Integration Examples

### With Devise

```ruby
# app/controllers/users/mfa_controller.rb
class Users::MfaController < ApplicationController
  before_action :authenticate_user!

  def show
    # Display MFA setup page
  end

  def create
    if current_user.verify_numeric_code(params[:code])
      sign_in current_user, bypass: true
      redirect_to root_path
    else
      flash[:alert] = "Invalid code"
      redirect_to users_mfa_path
    end
  end

  def send_code
    current_user.send_numeric_code(via: params[:method].to_sym)
    flash[:notice] = "Verification code sent"
    redirect_to users_mfa_path
  end
end
```

Add routes:

```ruby
# config/routes.rb
devise_for :users
namespace :users do
  resource :mfa, only: [:show, :create] do
    post :send_code
  end
end
```

### With Custom Authentication

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      if user.mfa_enabled?
        # Store user ID in session temporarily
        session[:pending_mfa_user_id] = user.id
        user.send_numeric_code(via: :sms)
        redirect_to mfa_verification_path
      else
        # No MFA required, log them in
        session[:user_id] = user.id
        redirect_to dashboard_path
      end
    else
      flash[:error] = "Invalid credentials"
      render :new
    end
  end
end

# app/controllers/mfa_verifications_controller.rb
class MfaVerificationsController < ApplicationController
  def show
    # Display MFA verification form
  end

  def create
    user = User.find(session[:pending_mfa_user_id])

    if user.verify_numeric_code(params[:code])
      session.delete(:pending_mfa_user_id)
      session[:user_id] = user.id
      redirect_to dashboard_path
    else
      flash[:error] = "Invalid verification code"
      render :show
    end
  end
end
```

## Provider Configuration Examples

RailsMFA is **fully provider-agnostic**. You can use any SMS or email service by providing a simple lambda function. Here are examples for popular providers:

### SMS Provider Examples

#### Twilio

```ruby
# config/initializers/rails_mfa.rb
RailsMFA.configure do |config|
  config.sms_provider = lambda do |to, message|
    require 'twilio-ruby'

    client = Twilio::REST::Client.new(
      ENV['TWILIO_ACCOUNT_SID'],
      ENV['TWILIO_AUTH_TOKEN']
    )

    client.messages.create(
      from: ENV['TWILIO_PHONE_NUMBER'],
      to: to,
      body: message
    )
  end
end
```

#### AWS SNS

```ruby
# config/initializers/rails_mfa.rb
RailsMFA.configure do |config|
  config.sms_provider = lambda do |to, message|
    require 'aws-sdk-sns'

    sns = Aws::SNS::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )

    sns.publish(
      phone_number: to,
      message: message
    )
  end
end
```

#### Vonage (Nexmo)

```ruby
RailsMFA.configure do |config|
  config.sms_provider = lambda do |to, message|
    require 'vonage'

    client = Vonage::Client.new(
      api_key: ENV['VONAGE_API_KEY'],
      api_secret: ENV['VONAGE_API_SECRET']
    )

    client.sms.send(
      from: ENV['VONAGE_PHONE_NUMBER'],
      to: to,
      text: message
    )
  end
end
```

#### MessageBird

```ruby
RailsMFA.configure do |config|
  config.sms_provider = lambda do |to, message|
    require 'messagebird'

    client = MessageBird::Client.new(ENV['MESSAGEBIRD_API_KEY'])

    client.message_create(
      ENV['MESSAGEBIRD_PHONE_NUMBER'],
      to,
      message
    )
  end
end
```

#### Plivo

```ruby
RailsMFA.configure do |config|
  config.sms_provider = lambda do |to, message|
    require 'plivo'

    client = Plivo::RestClient.new(
      ENV['PLIVO_AUTH_ID'],
      ENV['PLIVO_AUTH_TOKEN']
    )

    client.messages.create(
      src: ENV['PLIVO_PHONE_NUMBER'],
      dst: to,
      text: message
    )
  end
end
```

### Email Provider Examples

#### SendGrid

```ruby
# config/initializers/rails_mfa.rb
RailsMFA.configure do |config|
  config.email_provider = lambda do |to, subject, body|
    require 'sendgrid-ruby'
    include SendGrid

    from = Email.new(email: 'noreply@example.com')
    to = Email.new(email: to)
    content = Content.new(type: 'text/plain', value: body)
    mail = Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    sg.client.mail._('send').post(request_body: mail.to_json)
  end
end
```

### Custom ActionMailer Example

```ruby
# app/mailers/mfa_mailer.rb
class MfaMailer < ApplicationMailer
  def send_code(to, subject, body)
    @code = body
    mail(to: to, subject: subject)
  end
end

# config/initializers/rails_mfa.rb
RailsMFA.configure do |config|
  config.email_provider = lambda do |to, subject, body|
    MfaMailer.send_code(to, subject, body).deliver_now
  end
end
```

## Configuration Options

```ruby
RailsMFA.configure do |config|
  # SMS provider (required for SMS-based MFA)
  # Lambda that takes (phone_number, message) as arguments
  config.sms_provider = ->(to, message) { ... }

  # Email provider (required for email-based MFA)
  # Lambda that takes (email, subject, body) as arguments
  config.email_provider = ->(to, subject, body) { ... }

  # Length of numeric codes (default: 6)
  config.code_length = 6

  # Code expiration time in seconds (default: 300 = 5 minutes)
  config.code_expiry_seconds = 300

  # Token storage backend (default: Rails.cache or SimpleStore)
  config.token_store = Redis.new
end
```

## Testing

RailsMFA uses RSpec for testing. To run the test suite:

```bash
bundle exec rspec
```

### Testing in Your Application

You can stub the providers in your tests:

```ruby
RSpec.describe "MFA", type: :request do
  before do
    RailsMFA.configure do |config|
      config.sms_provider = ->(to, message) { "SMS sent" }
      config.email_provider = ->(to, subject, body) { "Email sent" }
    end
  end

  it "sends verification code" do
    user = create(:user)
    post send_code_path, params: { method: 'sms' }

    expect(response).to have_http_status(:success)
  end
end
```

## Security Considerations

1. **Encrypt MFA Secrets**: Always encrypt the `mfa_secret` column in your database using Rails' built-in encryption or a gem like `attr_encrypted`.

2. **HTTPS Only**: Always use HTTPS in production to prevent code interception.

3. **Rate Limiting**: Implement rate limiting on MFA endpoints to prevent brute-force attacks:

```ruby
# Use rack-attack or similar
throttle('mfa/verify', limit: 5, period: 5.minutes) do |req|
  req.ip if req.path == '/mfa/verify' && req.post?
end
```

4. **Secure Storage**: Use secure session storage (encrypted cookies or server-side sessions).

5. **Backup Codes**: Consider implementing backup codes for account recovery.

## Advanced Usage

### Using with Redis

```ruby
# config/initializers/rails_mfa.rb
RailsMFA.configure do |config|
  config.token_store = Redis.new(
    host: ENV['REDIS_HOST'],
    port: ENV['REDIS_PORT'],
    db: 1
  )
end
```

### Custom Token Length and Expiration

```ruby
# Generate an 8-digit code that expires in 10 minutes
user.send_numeric_code(via: :email)

# Configure globally
RailsMFA.configure do |config|
  config.code_length = 8
  config.code_expiry_seconds = 600
end
```

### Checking TOTP Status

```ruby
# Check if user has TOTP set up
if user.mfa_secret.present? && user.mfa_enabled?
  # User has TOTP configured
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shoaibmalik786/rails_mfa.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits

Created by [Shoaib Malik](https://github.com/shoaibmalik786)

## Support

If you have any questions or need help integrating RailsMFA, please open an issue on GitHub.
