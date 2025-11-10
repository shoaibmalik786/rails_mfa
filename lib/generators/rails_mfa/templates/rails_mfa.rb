# frozen_string_literal: true

RailsMFA.configure do |config|
  # ============================================================================
  # SMS Provider Configuration
  # ============================================================================
  # Define your SMS provider here. This is a lambda that receives (phone_number, message)
  # and sends the SMS. You can use any SMS service (Twilio, AWS SNS, Vonage, etc.)
  #
  # Example with Twilio:
  # config.sms_provider = lambda do |to, message|
  #   twilio_client = Twilio::REST::Client.new(
  #     ENV['TWILIO_ACCOUNT_SID'],
  #     ENV['TWILIO_AUTH_TOKEN']
  #   )
  #   twilio_client.messages.create(
  #     from: ENV['TWILIO_PHONE_NUMBER'],
  #     to: to,
  #     body: message
  #   )
  # end
  #
  # Example with AWS SNS:
  # config.sms_provider = lambda do |to, message|
  #   sns = Aws::SNS::Client.new(region: ENV['AWS_REGION'])
  #   sns.publish(phone_number: to, message: message)
  # end
  #
  config.sms_provider = lambda do |to, message|
    # TODO: Implement your SMS provider here
    Rails.logger.info "SMS to #{to}: #{message}"
  end

  # ============================================================================
  # Email Provider Configuration
  # ============================================================================
  # Define your email provider here. This is a lambda that receives (email, subject, body)
  # and sends the email. You can use ActionMailer or any email service.
  #
  # Example with ActionMailer:
  # config.email_provider = lambda do |to, subject, body|
  #   MfaMailer.send_code(to, subject, body).deliver_now
  # end
  #
  # Example with SendGrid:
  # config.email_provider = lambda do |to, subject, body|
  #   mail = SendGrid::Mail.new(
  #     from: SendGrid::Email.new(email: 'noreply@example.com'),
  #     subject: subject,
  #     to: SendGrid::Email.new(email: to),
  #     content: SendGrid::Content.new(type: 'text/plain', value: body)
  #   )
  #   sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
  #   sg.client.mail._('send').post(request_body: mail.to_json)
  # end
  #
  config.email_provider = lambda do |to, subject, body|
    # TODO: Implement your email provider here
    Rails.logger.info "Email to #{to}: #{subject} - #{body}"
  end

  # ============================================================================
  # Token Configuration
  # ============================================================================
  # Length of the numeric verification code (default: 6)
  config.code_length = 6

  # How long the verification code is valid in seconds (default: 300 = 5 minutes)
  config.code_expiry_seconds = 300

  # ============================================================================
  # Cache Store Configuration
  # ============================================================================
  # Token storage backend (default: Rails.cache)
  # You can use Redis for better performance:
  # config.token_store = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'], db: 1)
  #
  # Or use the default Rails cache:
  # config.token_store = Rails.cache
end
