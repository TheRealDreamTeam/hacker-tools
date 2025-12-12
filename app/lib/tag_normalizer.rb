# Utility for normalizing tag names according to project standards
# Rules:
# - Always lowercase
# - Prefer single words
# - If multiple words, use kebab-case (word-word)
# - Max 2 parts in kebab-case
# - Tags with more than 2 parts should be split appropriately
module TagNormalizer
  # Normalize a single tag name according to project standards
  # Returns an array of normalized tag names (may split multi-part tags)
  def self.normalize(tag_name)
    return [] if tag_name.blank?

    # Convert to lowercase and strip whitespace
    normalized = tag_name.to_s.downcase.strip

    # Remove special characters except hyphens and alphanumeric
    normalized = normalized.gsub(/[^a-z0-9\s-]/, "")

    # Split by common separators (hyphens, underscores, spaces)
    parts = normalized.split(/[\s_-]+/).reject(&:blank?)

    return [] if parts.empty?

    # If single word, return as-is
    return [normalized] if parts.length == 1

    # If 2 parts, return as kebab-case
    return ["#{parts[0]}-#{parts[1]}"] if parts.length == 2

    # If more than 2 parts, split intelligently
    # Strategy: Create combinations that make sense
    # Example: "ai-assisted-coding" -> ["ai", "ai-assisted", "coding"]
    split_tags = []

    # Always include the first part as a standalone tag
    split_tags << parts[0]

    # Create 2-part combination from first 2 parts
    if parts.length >= 2
      split_tags << "#{parts[0]}-#{parts[1]}"
    end

    # Add the last part as standalone (if there are 3+ parts)
    # For "ai-assisted-coding": add "coding" (the last part)
    if parts.length > 2
      last_part = parts[-1]
      split_tags << last_part if last_part.length > 2 # Only add if meaningful (more than 2 chars)
    end

    # Remove duplicates while preserving order
    split_tags.uniq
  end

  # Normalize multiple tag names
  # Returns a flattened array of normalized tag names
  def self.normalize_all(tag_names)
    return [] if tag_names.blank?

    tag_names.flat_map { |name| normalize(name) }.uniq
  end
end

