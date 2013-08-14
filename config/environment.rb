# Load the rails application
require File.expand_path('../application', __FILE__)

# Sendgrid email configuration
ActionMailer::Base.smtp_settings = {
  :address        => 'smtp.sendgrid.net',
  :port           => '587',
  :authentication => :plain,
  :user_name      => 'kebrahim', #ENV['SENDGRID_USERNAME'],
  :password       => 'karmapo5', #ENV['SENDGRID_PASSWORD'],
  :domain         => 'fischmadness.herokuapp.com',
  :enable_starttls_auto => true
}

# Initialize the rails application
Jfisch::Application.initialize!
