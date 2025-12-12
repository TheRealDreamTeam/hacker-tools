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

  # Render a clickable tag link with hover tooltip showing description
  # Opens tag show page in new tab
  # @param tag [Tag] The tag to render
  # @param options [Hash] Additional options for the badge
  # @option options [String] :badge_class Additional CSS classes for the badge
  # @option options [String] :style Inline styles for the badge
  # @return [String] HTML for the tag link
  def render_tag_link(tag, options = {})
    badge_class = tag_badge_class(tag.tag_type)
    badge_class += " #{options[:badge_class]}" if options[:badge_class].present?

    # Build tooltip title with description if available
    tooltip_title = tag.tag_description.presence || tag.display_name

    # Build link attributes
    link_attributes = {
      target: "_blank",
      rel: "noopener noreferrer",
      class: "badge #{badge_class} text-decoration-none tag-link",
      data: {
        bs_toggle: "tooltip",
        bs_title: tooltip_title,
        bs_placement: "top"
      },
      title: tooltip_title
    }
    
    # Add inline styles if provided
    link_attributes[:style] = options[:style] if options[:style].present?

    # Create link with tooltip attributes
    link_to tag_path(tag), link_attributes do
      tag.display_name
    end
  end
end

