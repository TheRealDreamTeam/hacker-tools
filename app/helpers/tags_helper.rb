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
  # Always includes explicit text color class for good contrast
  def tag_badge_class(tag)
    base_class = if tag.respond_to?(:color) && tag.color.present?
      COLOR_BADGE_CLASSES[tag.color.downcase] || "bg-secondary"
    else
      # Fallback to tag_type_slug-based badge class
      tag_type_slug = tag.respond_to?(:tag_type_slug) ? tag.tag_type_slug : tag.to_s
      case tag_type_slug
      when "content-type"
        "bg-warning"
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
        "bg-info"
      when "task"
        "bg-primary"
      when "level"
        "bg-success"
      else
        "bg-secondary"
      end
    end
    
    # Ensure explicit text color is always included for good contrast
    # All badges use white text for consistency (except warning which uses dark text)
    if base_class.include?("bg-warning")
      base_class += " text-dark" unless base_class.include?("text-")
    else
      base_class += " text-white" unless base_class.include?("text-")
    end
    
    base_class
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
      # Use white text for all badges for consistency (except warning/yellow which uses dark text)
      if tag.color.downcase == "yellow" || tag.color.downcase == "light orange"
        inline_styles << "color: #212529 !important;" # Dark text for light backgrounds
      else
        inline_styles << "color: #ffffff !important;" # White text for all other badges
      end
    else
      # Ensure white text even when no color is set (for grey badges)
      inline_styles << "color: #ffffff !important;"
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
  
  # Calculate if a hex color is dark (needs white text) or light (needs dark text)
  # Uses relative luminance calculation (WCAG standard)
  def is_dark_background?(hex_color)
    return false if hex_color.blank?
    
    # Remove # if present
    hex = hex_color.gsub("#", "")
    
    # Convert hex to RGB
    r = hex[0..1].to_i(16)
    g = hex[2..3].to_i(16)
    b = hex[4..5].to_i(16)
    
    # Calculate relative luminance (WCAG formula)
    # Normalize RGB values to 0-1 range
    r_norm = r / 255.0
    g_norm = g / 255.0
    b_norm = b / 255.0
    
    # Apply gamma correction
    r_gamma = r_norm <= 0.03928 ? r_norm / 12.92 : ((r_norm + 0.055) / 1.055) ** 2.4
    g_gamma = g_norm <= 0.03928 ? g_norm / 12.92 : ((g_norm + 0.055) / 1.055) ** 2.4
    b_gamma = b_norm <= 0.03928 ? b_norm / 12.92 : ((b_norm + 0.055) / 1.055) ** 2.4
    
    # Calculate luminance
    luminance = 0.2126 * r_gamma + 0.7152 * g_gamma + 0.0722 * b_gamma
    
    # If luminance is less than 0.5, it's a dark background (needs white text)
    luminance < 0.5
  end
end

