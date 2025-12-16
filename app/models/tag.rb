class Tag < ApplicationRecord
  # Self-referential parent-child relationship for tag hierarchies
  belongs_to :parent, class_name: "Tag", optional: true
  has_many :children, class_name: "Tag", foreign_key: "parent_id", dependent: :nullify

  # Many-to-many with tools
  has_many :tool_tags, dependent: :destroy
  has_many :tools, through: :tool_tags
  
  # Many-to-many with submissions
  has_many :submission_tags, dependent: :destroy
  has_many :submissions, through: :submission_tags

  # Followable
  has_many :follows, as: :followable, dependent: :destroy
  has_many :followers, through: :follows, source: :user

  # Validations
  validates :tag_name, presence: true, uniqueness: { case_sensitive: false }
  validates :tag_type, presence: true
  validates :tag_type_id, presence: true
  validates :tag_type_slug, presence: true
  validate :no_circular_parent_reference
  before_validation :normalize_tag_name
  before_validation :normalize_tag_slug
  before_validation :populate_tag_type_fields

  # Normalize tag name to lowercase before validation
  def normalize_tag_name
    return if tag_name.blank?

    self.tag_name = tag_name.downcase.strip
  end

  # Normalize tag slug if not provided (generate from tag_name)
  def normalize_tag_slug
    return if tag_slug.present?

    self.tag_slug = tag_name&.parameterize if tag_name.present?
  end

  # Populate tag_type_id and tag_type_slug from tag_type if tag_type is set
  def populate_tag_type_fields
    return unless tag_type.present?

    mapping = self.class.tag_type_mapping(tag_type)
    if mapping
      self.tag_type_id = mapping[:tag_type_id] if tag_type_id.blank?
      self.tag_type_slug = mapping[:tag_type_slug] if tag_type_slug.blank?
    end
  end

  # Scopes
  scope :roots, -> { where(parent_id: nil) }
  scope :by_type, -> { order(tag_type_id: :asc, tag_type: :asc, tag_name: :asc) }
  scope :by_type_slug, ->(slug) { where(tag_type_slug: slug) }
  scope :with_children, -> { includes(:children) }

  # Helper method to display tag name (without parent prefix)
  def display_name
    tag_name
  end

  # Get the color for this tag (uses tag.color if set, otherwise falls back to helper)
  def color_value
    color.presence || "gray"
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

  # Tag type mappings - defines all available tag types with their IDs and slugs
  # Used for form dropdowns and auto-population
  def self.tag_type_options
    [
      { tag_type: "Platform", tag_type_id: 1, tag_type_slug: "platform" },
      { tag_type: "Content Type", tag_type_id: 2, tag_type_slug: "content-type" },
      { tag_type: "Programming Language", tag_type_id: 3, tag_type_slug: "programming-language" },
      { tag_type: "Language Version", tag_type_id: 4, tag_type_slug: "programming-language-version" },
      { tag_type: "Framework", tag_type_id: 5, tag_type_slug: "framework" },
      { tag_type: "Framework Version", tag_type_id: 6, tag_type_slug: "framework-version" },
      { tag_type: "Dev Tool", tag_type_id: 7, tag_type_slug: "dev-tool" },
      { tag_type: "Database", tag_type_id: 8, tag_type_slug: "database" },
      { tag_type: "Cloud Platform", tag_type_id: 9, tag_type_slug: "cloud-platform" },
      { tag_type: "Cloud Service", tag_type_id: 10, tag_type_slug: "cloud-service" },
      { tag_type: "Topic", tag_type_id: 11, tag_type_slug: "topic" },
      { tag_type: "Task", tag_type_id: 12, tag_type_slug: "task" },
      { tag_type: "Level", tag_type_id: 13, tag_type_slug: "level" }
    ]
  end

  # Get tag type mapping by tag_type name
  def self.tag_type_mapping(tag_type_name)
    tag_type_options.find { |opt| opt[:tag_type] == tag_type_name }
  end

  # Color options for dropdown
  def self.color_options
    [
      "yellow", "black", "grey", "gray", "green", "indigo", "navy", 
      "purple", "cyan", "blue", "light green", "light orange", "light red"
    ]
  end

  # Icon options for dropdown
  def self.icon_options
    [
      "📝", "📘", "📖", "💻", "🎥", "🎙️", "💾", "🌍", "🐦", "💬", "🎓", "🎤", "🧾",
      "🔗", "⌨️", "🔢", "🧩", "🛠️", "🗄️", "☁️", "🔧", "🧠", "✅", "🎚️"
    ]
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

