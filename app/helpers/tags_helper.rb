module TagsHelper
  # Color mapping for tag type slugs (fallback if tag.color is not set)
  TAG_TYPE_SLUG_COLORS = {
    "content-type" => "#ffc107",              # yellow
    "platform" => "#000000",                 # black
    "programming-language" => "#6c757d",      # grey
    "programming-language-version" => "#6c757d", # grey
    "framework" => "#198754",                 # green
    "framework-version" => "#198754",         # green
    "dev-tool" => "#6610f2",                  # indigo
    "database" => "#001f3f",                   # navy
    "cloud-platform" => "#6f42c1",            # purple
    "cloud-service" => "#6f42c1",            # purple
    "topic" => "#0dcaf0",                     # cyan
    "task" => "#0d6efd",                      # blue
    "level" => "#20c997"                     # teal (light green)
  }.freeze

  # Color name to Bootstrap badge class mapping
  COLOR_BADGE_CLASSES = {
    "yellow" => "bg-warning text-dark",
    "black" => "bg-dark",
    "grey" => "bg-secondary",
    "gray" => "bg-secondary",
    "green" => "bg-success",
    "indigo" => "bg-primary",
    "navy" => "bg-dark",
    "purple" => "bg-primary",
    "cyan" => "bg-info text-dark",
    "blue" => "bg-primary",
    "light green" => "bg-success",
    "light orange" => "bg-warning text-dark",
    "light red" => "bg-danger"
  }.freeze

  # Get color for a tag (uses tag.color if set, otherwise falls back to tag_type_slug)
  # Returns hex color value
  def tag_type_color(tag)
    # If tag has a color attribute, convert it to hex
    if tag.respond_to?(:color) && tag.color.present?
      return color_name_to_hex(tag.color)
    end

    # Fallback to tag_type_slug-based color
    tag_type_slug = tag.respond_to?(:tag_type_slug) ? tag.tag_type_slug : tag.to_s
    TAG_TYPE_SLUG_COLORS[tag_type_slug] || "#6c757d"
  end

  # Get badge class for a tag (uses tag.color if set, otherwise falls back to tag_type_slug)
  def tag_badge_class(tag)
    # If tag has a color attribute, use it
    if tag.respond_to?(:color) && tag.color.present?
      return COLOR_BADGE_CLASSES[tag.color.downcase] || "bg-secondary"
    end

    # Fallback to tag_type_slug-based badge class
    tag_type_slug = tag.respond_to?(:tag_type_slug) ? tag.tag_type_slug : tag.to_s
    case tag_type_slug
    when "content-type"
      "bg-warning text-dark"
    when "platform"
      "bg-dark"
    when "programming-language", "programming-language-version"
      "bg-secondary"
    when "framework", "framework-version"
      "bg-success"
    when "dev-tool"
      "bg-primary"
    when "database"
      "bg-dark"
    when "cloud-platform", "cloud-service"
      "bg-primary"
    when "topic"
      "bg-info text-dark"
    when "task"
      "bg-primary"
    when "level"
      "bg-success"
    else
      "bg-secondary"
    end
  end

  # Render a clickable tag link with hover tooltip showing description
  # Opens tag show page in new tab
  # Uses tag.color for background color if available
  # @param tag [Tag] The tag to render
  # @param options [Hash] Additional options for the badge
  # @option options [String] :badge_class Additional CSS classes for the badge
  # @option options [String] :style Inline styles for the badge
  # @return [String] HTML for the tag link
  def render_tag_link(tag, options = {})
    # Use tag's color for background if available
    badge_class = tag_badge_class(tag)
    badge_class += " #{options[:badge_class]}" if options[:badge_class].present?

    # Build tooltip title with description if available
    tooltip_title = tag.tag_description.presence || tag.display_name

    # Build inline styles - use tag.color if available
    inline_styles = []
    if tag.respond_to?(:color) && tag.color.present?
      # Map color name to hex value for background
      color_hex = color_name_to_hex(tag.color)
      inline_styles << "background-color: #{color_hex};"
      # Use white text for dark backgrounds, dark text for light backgrounds
      if ["black", "navy", "purple", "indigo", "blue"].include?(tag.color.downcase)
        inline_styles << "color: #ffffff;"
      else
        inline_styles << "color: #000000;"
      end
    end
    
    # Add any additional styles from options
    if options[:style].present?
      inline_styles << options[:style]
    end

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
    
    # Add inline styles if we have any
    link_attributes[:style] = inline_styles.join(" ") if inline_styles.any?

    # Create link with tooltip attributes
    link_to tag_path(tag), link_attributes do
      tag.display_name
    end
  end

  # Map color name to hex value (public helper method for use in views)
  def color_name_to_hex(color_name)
    color_map = {
      "yellow" => "#ffc107",
      "black" => "#000000",
      "grey" => "#6c757d",
      "gray" => "#6c757d",
      "green" => "#198754",
      "indigo" => "#6610f2",
      "navy" => "#001f3f",
      "purple" => "#6f42c1",
      "cyan" => "#0dcaf0",
      "blue" => "#0d6efd",
      "light green" => "#20c997",
      "light orange" => "#ffc107",
      "light red" => "#dc3545"
    }
    color_map[color_name.downcase] || "#6c757d"
  end

  # Determine if a color name is dark (returns true for dark colors that need white text)
  def is_dark_color?(color_name)
    return false if color_name.blank?
    
    dark_colors = ["black", "navy", "purple", "indigo", "blue"]
    dark_colors.include?(color_name.downcase)
  end
end

