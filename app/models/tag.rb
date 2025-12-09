class Tag < ApplicationRecord
  # Self-referential parent-child relationship for tag hierarchies
  belongs_to :parent, class_name: "Tag", optional: true
  has_many :children, class_name: "Tag", foreign_key: "parent_id", dependent: :nullify

  # Many-to-many with tools
  has_many :tool_tags, dependent: :destroy
  has_many :tools, through: :tool_tags

  validates :tag_name, presence: true, uniqueness: true
end

