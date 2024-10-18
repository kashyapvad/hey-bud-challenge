class SocialPresence
  include Mongoid::Document
  include Mongoid::Timestamps
  include TrackAnalytics
  include ActiveModel::SecurePassword
  include PersonalContactInfo

  PROVIDER_USERNAME_PASSWORD = "username_password"
  PROVIDER_GOOGLE = "google_oauth2"
  PROVIDER_FACEBOOK = "facebook"
  PROVIDER_TWITTER = "twitter"

  belongs_to :user, index: true

  field :is_preferred, type: :boolean, default: false

  field :provider
  field :uid
  field :credentials, type: :hash

  # presence
  field :nickname
  field :photo_url
  field :profile_url

  # profile
  field :username
  field :bio
  field :gender
  field :born_on
  field :location
  field :timezone
  field :locale
  field :is_verified, type: :boolean, default: false

  # social graph
  field :following
  field :followers
  field :connections # aka friends
  field :interests

  # activity
  field :sign_in_count, type: :integer, default: 0
  field :last_signed_in_at, type: :date_time, default: ->{ DateTime.now.utc }

  field :extra_info, type: :hash

  field :legacy, type: :hash, default:nil

  # custom login
  field :password_digest
  has_secure_password validations: false

  has_one :avatar, class_name: "Attachment", as: :attached_photo, dependent: :destroy
  has_many :password_reset_requests, dependent: :destroy

  scope :phone, ->{where(provider: 'phone') }
  scope :gmail, ->{where(provider: 'google_oauth2') }
  scope :twitter, ->{where(provider: 'twitter') }
  scope :facebook, ->{where(provider: 'facebook') }
  scope :username_password, ->{where(provider: 'username_password') }
  scope :recent, ->{order_by(last_signed_in_at: :desc)}

  before_validation :downcase_email, if: :email
  before_validation :ensure_uid_for_username_password, if: :username_password_provider?
  validates_presence_of :password, on: :create, if: :username_password_provider?
  validates :password, confirmation: {message: 'Passwords do not match.'}, if: :username_password_provider?

  # index({ provider: 1, uid: 1 }, unique: true, background: true)

  def avatar_url
    return nil unless !!avatar
    avatar.url
  end

  def mark_sign_in
    update sign_in_count: (sign_in_count + 1), last_signed_in_at: Time.now
    member.update sign_in_count: (member.sign_in_count + 1), last_signed_in_at: Time.now, login_attempts: 0
  end

  def email_domain
    email.to_s.downcase.split('@').last
  end

  def name
    name = first_name+' '+last_name if !!first_name and !!last_name
    name ||= first_name if !last_name
    name ||= last_name if !first_name
    name
  end

  def update_member top_org_atts = {}, tos_params = {}
    member.market_type ||= market_type
    member.email ||= email
    member.save
    rep = member.rep
    rep = member.build_rep if rep.nil?
    rep.email ||= email
    rep.first_name ||= first_name
    rep.last_name ||= last_name
    rep.email ||= email
    rep.email2 ||= email2
    rep.title ||= title
    rep.phone ||= phone
    rep.role ||= role
    unless tos_params.empty?
      if market_type.to_s.downcase.eql? "supplier"
        rep.supplier_terms_of_service = tos_params[:supplier_terms_of_service].to_h if tos_params[:supplier_terms_of_service]
        rep.supplier_data_policy = tos_params[:supplier_data_policy].to_h if tos_params[:supplier_data_policy]
      elsif market_type.to_s.downcase.eql? "buyer"
        rep.sponsor_terms_of_service = tos_params[:sponsor_terms_of_service].to_h if tos_params[:sponsor_terms_of_service]
        rep.sponsor_data_policy = tos_params[:sponsor_data_policy].to_h if tos_params[:sponsor_data_policy]
      end
    end
    rep.save
    rep.register_activation_state!
    member
  end

  def self.authenticate_from_google presence, omniauth
    atts = {}
    if omniauth.credentials
      atts.merge!({ credentials: omniauth.credentials.to_hash })
    end
    if omniauth.info
      info = omniauth.info
      profile_url = info.urls.Google if info.urls and info.urls.Google
      atts.merge!({
        username:     get_username_from_email(info.email),
        first_name:   info.first_name,
        last_name:    info.last_name,
        nickname:     info.name,
        email:        info.email,
        photo_url:    info.image,
        profile_url:  profile_url,
      })
    end
    presence.update_attributes atts
  end

  def self.authenticate_from_facebook presence, omniauth
    atts = {}

    if omniauth.credentials
      atts.merge!({ credentials: omniauth.credentials.to_hash })
    end

    if omniauth.extra and omniauth.extra.raw_info
      raw_info = omniauth.extra.raw_info
      info = omniauth.info

      atts.merge!({
        first_name:   info.first_name,
        last_name:    info.last_name,
        photo_url:    info.image,
        email:        info.email,
        profile_url:  raw_info.link
      })
    end

    presence.update_attributes atts
  end

  def self.authenticate_from_twitter presence, omniauth
    atts = {}

    if omniauth.credentials
      atts.merge!({ credentials: omniauth.credentials.to_hash })
    end

    if omniauth.extra and omniauth.extra.raw_info
      raw_info = omniauth.extra.raw_info
      info = omniauth.info

      atts.merge!({
        nickname:     info.nickname,
        username:     "@#{info.nickname}",
        photo_url:    info.image,
        profile_url:  info.urls.Twitter
      })
    end

    presence.update_attributes atts
  end

  def self.authenticate omniauth
    provider = omniauth['provider'].downcase
    uid = omniauth['uid'].to_s
    user_info = omniauth['user_info'] || {}
    presence = SocialPresence.where(provider: provider, uid: uid).first_or_create

    case provider.to_sym
    when :google_oauth2
      authenticate_from_google presence, omniauth
    when :facebook
      authenticate_from_facebook presence, omniauth
    when :twitter
      authenticate_from_twitter presence, omniauth
    end
    presence
  end

  def authenticate_for_username_and_password! password
    return self if authenticate password
    errors.add(:password, :invalid, message: 'Password is invalid.')
    raise "Password is invalid."
  end

  def valid_password? password
    password and password.length >= 3
  end

private

  def self.get_username_from_email email
    email.to_s.split('@').first
  end

  def downcase_email
    email.downcase!
  end

  def username_password_provider?
    provider.eql? 'username_password'
  end

  def ensure_uid_for_username_password
    self.uid ||= email
  end
end
