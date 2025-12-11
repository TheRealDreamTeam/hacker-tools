class Tag < ApplicationRecord
  # Self-referential parent-child relationship for tag hierarchies
  belongs_to :parent, class_name: "Tag", optional: true
  has_many :children, class_name: "Tag", foreign_key: "parent_id", dependent: :nullify

  # Many-to-many with tools
  has_many :tool_tags, dependent: :destroy
  has_many :tools, through: :tool_tags

  # Followable
  has_many :follows, as: :followable, dependent: :destroy
  has_many :followers, through: :follows, source: :user

  # Tag types enum - categories for organizing tags
  enum tag_type: {
    category: 0,
    language: 1,
    framework: 2,
    library: 3,
    version: 4,
    platform: 5,
    other: 6
  }, _prefix: :tag_type

  validates :tag_name, presence: true, uniqueness: { case_sensitive: false }
  validates :tag_type, presence: true
  validate :no_circular_parent_reference

  # Scopes
  scope :roots, -> { where(parent_id: nil) }
  scope :by_type, -> { order(tag_type: :asc, tag_name: :asc) }
  scope :with_children, -> { includes(:children) }

  # Helper method to display tag with parent hierarchy
  def display_name
    parent ? "#{parent.tag_name} / #{tag_name}" : tag_name
  end

  # Get all ancestors (parent chain)
  def ancestors
    return [] unless parent

    [parent] + parent.ancestors
  end

  # Check if tag is a root (no parent)
  def root?
    parent_id.nil?
  end

  private

  # Prevent circular parent references
  def no_circular_parent_reference
    return unless parent_id.present?

    if parent_id == id
      errors.add(:parent_id, "cannot be self")
      return
    end

    # Check if parent is in the ancestry chain
    if parent&.ancestors&.include?(self)
      errors.add(:parent_id, "would create a circular reference")
    end
  end
end

