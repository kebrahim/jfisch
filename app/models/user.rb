class User < ActiveRecord::Base
  extend Enumerize

  attr_accessible :email, :first_name, :last_name, :password, :password_confirmation, :role,
                  :captain_code, :referred_by, :send_emails, :time_zone, :is_confirmed,
                  :confirmation_token

  enumerize :role, in: [:demo, :user, :captain, :admin, :super_admin]

  attr_accessor :password
  before_save :encrypt_password
  before_create { generate_token(:auth_token) }
  
  validates_confirmation_of :password
  validates_presence_of :password, :on => :create
  validates_presence_of :password_confirmation, :on => :create
  validates_presence_of :email
  validates_uniqueness_of :email, :case_sensitive => false
  validates_presence_of :first_name
  validates_presence_of :last_name
  validates_presence_of :role
  validates_presence_of :captain_code
  validates_presence_of :time_zone

  ALL_ROLES_ARRAY = [:user, :captain, :admin, :super_admin, :demo]
  ASSIGNABLE_ROLES = { admin: [:user, :captain, :admin, :demo],
                       super_admin: ALL_ROLES_ARRAY }

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

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end

  def send_password_reset
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    save!
    UserMailer.password_reset(self).deliver
  end

  def send_confirmation
    generate_token(:confirmation_token)
    self.is_confirmed = false
    save!
    UserMailer.account_confirmation(self).deliver
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

  # returns true if this user is an admin or super-admin
  def is_admin
    return [:admin.to_s, :super_admin.to_s].include?(self.role)
  end

  # returns true if this user is a super-admin
  def is_super_admin
    return self.role == :super_admin.to_s
  end

  # returns true if this user is a captain
  def is_captain
    return self.role == :captain.to_s
  end

  # returns the role associated with this user's role string
  def role_type
    return User.role_type_from_string(self.role)
  end

  # returns the role associated with the specified role string
  def self.role_type_from_string(role_string)
    ALL_ROLES_ARRAY.each { |role|
      if role.to_s == role_string
        return role
      end
    }
    return nil
  end
end
