# app/models/user.rb
class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :email,           type: String
  field :api_key,         type: String

  belongs_to :organization, index: true
  has_many :social_presences

  before_create :generate_api_key

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, on: :create
  validates :organization, presence: true

  private

  def generate_api_key
    self.api_key = SecureRandom.hex(20)
  end
end
