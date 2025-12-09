class List < ApplicationRecord
  belongs_to :user

  # Many-to-many with tools
  has_many :list_tools, dependent: :destroy
  has_many :tools, through: :list_tools

  validates :list_name, presence: true
end

