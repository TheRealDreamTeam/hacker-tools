class List < ApplicationRecord
  belongs_to :user

  # Many-to-many with tools
  has_many :list_tools, dependent: :destroy
  has_many :tools, through: :list_tools
  
  # Many-to-many with submissions
  has_many :list_submissions, dependent: :destroy
  has_many :submissions, through: :list_submissions

  # Followable
  has_many :follows, as: :followable, dependent: :destroy
  has_many :followers, through: :follows, source: :user

  # Visibility enum: private (0) or public (1)
  enum visibility: { private: 0, public: 1 }, _prefix: :visibility

  validates :list_name, presence: true
  validates :list_name, uniqueness: { scope: :user_id }
  validates :visibility, presence: true

  # Scopes for filtering
  scope :public_lists, -> { where(visibility: visibilities[:public]) }
  scope :recent, -> { order(created_at: :desc) }

  # Helper methods
  def follower_count
    follows.count
  end

  def followed_by?(user)
    return false unless user

    follows.exists?(user: user)
  end
end

