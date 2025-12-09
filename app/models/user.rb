class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Active Storage avatar to avoid storing URLs directly and allow variants.
  has_one_attached :avatar

  # Associations
  has_many :tools, dependent: :destroy
  has_many :lists, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :user_tools, dependent: :destroy
  has_many :comment_upvotes, dependent: :destroy

  # Through associations
  has_many :upvoted_tools, -> { where(user_tools: { upvote: true }) }, through: :user_tools, source: :tool
  has_many :favorited_tools, -> { where(user_tools: { favorite: true }) }, through: :user_tools, source: :tool
  has_many :subscribed_tools, -> { where(user_tools: { subscribe: true }) }, through: :user_tools, source: :tool

  validates :username, presence: true, uniqueness: true

  # Helper methods
  def upvoted_tools_count
    user_tools.where(upvote: true).count
  end

  def favorite_count
    user_tools.where(favorite: true).count
  end
end
