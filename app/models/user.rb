class User < ApplicationRecord
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable, authentication_keys: [:login]
    attr_writer :login
    scope :online, lambda{ where("updated_at > ?", 10.minutes.ago) }
    has_many :events
    acts_as_messageable


    validates :username,
              presence: true,
              uniqueness: {
                  case_sensitive: false
              } # etc.
    extend FriendlyId
    friendly_id :username, use: :slugged

    validate :validate_username
    validate :validate_student_id
    def validate_username
        errors.add(:username, :invalid) if User.where(email: username).exists?
    end
    def mailboxer_email(object)
      return email
    end
    def login
        @login || username || email
    end
    def online?
      updated_at > 10.minutes.ago
    end

    def self.find_first_by_auth_conditions(warden_conditions)
        conditions = warden_conditions.dup
        if login = conditions.delete(:login)
            where(conditions).where(['lower(username) = :value OR lower(email) = :value', { value: login.downcase }]).first
        else
            if conditions[:username].nil?
                where(conditions).first
            else
                where(username: conditions[:username]).first
            end
        end
    end

    def validate_student_id
      errors.add(:student_id, :invalid) if Student.all.where(:student_id => student_id) == [] || User.all.where(:student_id => student_id) != []
    end
end
