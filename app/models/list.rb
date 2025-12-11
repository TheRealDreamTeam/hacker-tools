class List < ApplicationRecord
  belongs_to :user

  # Many-to-many with tools
  has_many :list_tools, dependent: :destroy
  has_many :tools, through: :list_tools

  # Followable
  has_many :follows, as: :followable, dependent: :destroy
  has_many :followers, through: :follows, source: :user

  validates :list_name, presence: true
end

