module TagsHelper
  # Color mapping for tag types
  TAG_TYPE_COLORS = {
    category: "#6c757d",    # gray
    language: "#0d6efd",    # blue
    framework: "#198754",   # green
    library: "#ffc107",     # yellow
    version: "#fd7e14",     # orange
    platform: "#dc3545",   # red
    other: "#6f42c1"        # purple
  }.freeze

  def tag_type_color(tag_type)
    TAG_TYPE_COLORS[tag_type.to_sym] || TAG_TYPE_COLORS[:other]
  end

  def tag_badge_class(tag_type)
    case tag_type.to_sym
    when :category
      "bg-secondary"
    when :language
      "bg-primary"
    when :framework
      "bg-success"
    when :library
      "bg-warning text-dark"
    when :version
      "bg-info text-dark"
    when :platform
      "bg-danger"
    else
      "bg-dark"
    end
  end
end

