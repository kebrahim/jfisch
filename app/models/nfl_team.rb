class NflTeam < ActiveRecord::Base
  extend Enumerize

  attr_accessible :abbreviation, :city, :name, :conference, :division

  enumerize :conference, in: [:AFC, :NFC]
  enumerize :division, in: [:North, :South, :East, :West]

  def full_name
    return self.city + " " + self.name
  end
end
