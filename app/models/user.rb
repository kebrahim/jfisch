class User < ActiveRecord::Base
  attr_accessible :email, :first_name, :last_name, :password, :password_confirmation

  attr_accessor :password
  before_save :encrypt_password

  validates_confirmation_of :password
  validates_presence_of :password, :on => :create
  validates_presence_of :password_confirmation, :on => :create
  validates_presence_of :email
  validates_uniqueness_of :email
  validates_presence_of :first_name, :on => :create
  validates_presence_of :last_name, :on => :create

  def self.authenticate(email, password)
    user = find_by_email(email)
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil
    end
  end
  
  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end
  end

  # Returns the full name of the user
  def fullName
    return self.first_name + " " + self.last_name
  end

  # Overrides find_by_email to provide case-insensitive search, useful for logging in.
  def self.find_by_email(email)
    User.find(:all, :conditions => ["lower(email) = lower(?)", email]).first
  end
end
