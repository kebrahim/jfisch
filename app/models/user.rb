class User < ActiveRecord::Base
  attr_accessible :email, :first_name, :last_name, :password_hash, :password_salt
end
