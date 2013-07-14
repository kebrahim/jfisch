class User < ActiveRecord::Base
  extend Enumerize

  attr_accessible :email, :first_name, :last_name, :password, :password_confirmation, :role

  enumerize :role, in: [:demo, :user, :captain, :admin, :super_admin]

  attr_accessor :password
  before_save :encrypt_password

  validates_confirmation_of :password
  validates_presence_of :password, :on => :create
  validates_presence_of :password_confirmation, :on => :create
  validates_presence_of :email
  validates_uniqueness_of :email, :case_sensitive => false
  validates_presence_of :first_name
  validates_presence_of :last_name
  validates_presence_of :role

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
  def full_name
    return self.first_name + " " + self.last_name
  end

  # Overrides find_by_email to provide case-insensitive search, useful for logging in.
  def self.find_by_email(email)
    User.find(:all, :conditions => ["lower(email) = lower(?)", email]).first
  end

  # Finds a single user by its first and last names, using case-insensitive search.
  def self.find_by_names(first_name, last_name)
    User.find(:all, :conditions => ["lower(first_name) = lower(?) AND lower(last_name) = lower(?)", 
                                    first_name, last_name]).first
  end
end
