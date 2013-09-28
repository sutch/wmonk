class Url < ActiveRecord::Base
  validates_presence_of :value

  has_many :exchanges

  def self.find_by_encoded(encoded)
    self.find_by(value: self.decode(encoded))
  end

  def self.decode(encoded)
    Base64.urlsafe_decode64(encoded + '=' * ((4 - encoded.length % 4) % 4 ))
  end

  def encoded
    Base64.urlsafe_encode64(self.value).gsub(/=+$/, '')
  end

end
