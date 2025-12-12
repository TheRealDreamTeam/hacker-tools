# Job for discovering and enriching tool information from the internet
# Runs automatically when a new tool is created
#
# This job:
# 1. Uses RubyLLM to discover the tool's official website, GitHub repo, and description
# 2. Fetches discovered URLs to extract additional metadata (title, description, images)
# 3. Updates the tool with discovered information (tool_url, tool_description, icon, etc.)
#
# Data sources:
# - RubyLLM for intelligent discovery of official websites and GitHub repos
# - Web scraping (official website, GitHub pages) for metadata extraction
require "stringio"

class ToolDiscoveryJob < ApplicationJob
  queue_as :default

  # Retry on transient errors (network issues, rate limits, etc.)
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  # Discard if tool no longer exists
  discard_on ActiveRecord::RecordNotFound

  def perform(tool_id)
    tool = Tool.find_by(id: tool_id)
    return unless tool

    Rails.logger.info "Starting tool discovery for tool #{tool_id}: #{tool.tool_name}"

    # Step 1: Use RubyLLM to discover tool information
    discovery_result = discover_tool_info(tool)
    return unless discovery_result

    # Step 2: Update tool with discovered information
    update_tool_from_discovery(tool, discovery_result)

    # Step 3: If we found URLs, fetch and extract additional metadata
    enrich_from_urls(tool, discovery_result)

    # Step 4: Generate embedding for semantic search
    # Reload tool to get latest description and other fields
    tool.reload
    ToolEmbeddingGenerationJob.perform_later(tool.id)

    Rails.logger.info "Tool discovery completed for tool #{tool_id}: #{tool.tool_name}"
  rescue StandardError => e
    Rails.logger.error "Tool discovery error for tool #{tool_id}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    # Don't re-raise - tool discovery failures shouldn't break tool creation
  end

  private

  # Use RubyLLM to discover tool information
  def discover_tool_info(tool)
    # Skip if tool already has a URL and description (already enriched)
    return nil if tool.tool_url.present? && tool.tool_description.present? && tool.tool_description != "Auto-detected from submission"

    discovery_tool = ToolDiscoveryTool.new
    result = discovery_tool.execute(tool_name: tool.tool_name)

    # Only proceed if we got meaningful results with reasonable confidence
    return nil if result[:confidence].to_f < 0.5

    Rails.logger.info "Discovered info for #{tool.tool_name}: website=#{result[:official_website]}, github=#{result[:github_repo]}, confidence=#{result[:confidence]}"
    result
  rescue StandardError => e
    Rails.logger.warn "Tool discovery LLM call failed for #{tool.tool_name}: #{e.message}"
    nil
  end

  # Update tool with discovered information
  def update_tool_from_discovery(tool, discovery_result)
    updates = {}

    # Update tool_url if we discovered one and tool doesn't have one
    # Validate that the URL is actually a valid URL format before updating
    if discovery_result[:official_website].present? && tool.tool_url.blank?
      url = discovery_result[:official_website].strip
      if valid_url?(url)
        updates[:tool_url] = url
      else
        Rails.logger.warn "Skipping invalid URL for tool #{tool.id}: '#{url}'"
      end
    elsif discovery_result[:github_repo].present? && tool.tool_url.blank?
      # Prefer official website, but use GitHub if that's all we have
      url = discovery_result[:github_repo].strip
      if valid_url?(url)
        updates[:tool_url] = url
      else
        Rails.logger.warn "Skipping invalid GitHub URL for tool #{tool.id}: '#{url}'"
      end
    end

    # Update description if we got a better one
    if discovery_result[:description].present?
      current_desc = tool.tool_description
      # Only update if current description is auto-generated or blank
      if current_desc.blank? || current_desc == "Auto-detected from submission"
        updates[:tool_description] = discovery_result[:description]
      end
    end

    tool.update!(updates) if updates.any?
  end

  # Fetch URLs and extract additional metadata (title, description, images)
  def enrich_from_urls(tool, discovery_result)
    # Try official website first, then GitHub repo
    urls_to_fetch = []
    urls_to_fetch << discovery_result[:official_website] if discovery_result[:official_website].present?
    urls_to_fetch << discovery_result[:github_repo] if discovery_result[:github_repo].present? && urls_to_fetch.empty?

    urls_to_fetch.each do |url|
      next if url.blank?

      begin
        enrich_from_url(tool, url)
        # Only process first successful URL
        break
      rescue StandardError => e
        Rails.logger.warn "Failed to enrich tool #{tool.id} from URL #{url}: #{e.message}"
        # Continue to next URL
      end
    end
  end

  # Fetch a single URL and extract metadata
  def enrich_from_url(tool, url)
    Rails.logger.info "Fetching metadata from #{url} for tool #{tool.id}"

    response = Faraday.get(url) do |req|
      req.headers["User-Agent"] = "HackerTools/1.0"
      req.options.timeout = 10
    end

    return unless response.success?

    doc = Nokogiri::HTML(response.body)
    updates = {}

    # Extract description if we don't have a good one
    if tool.tool_description.blank? || tool.tool_description == "Auto-detected from submission"
      description = extract_description(doc)
      updates[:tool_description] = description if description.present? && description.length > 20
    end

    # Extract and attach icon/image
    icon_url = extract_icon_url(doc, url)
    if icon_url.present? && !tool.icon.attached?
      attach_icon_from_url(tool, icon_url)
    end

    tool.update!(updates) if updates.any?
  rescue Faraday::Error => e
    Rails.logger.warn "Failed to fetch URL #{url} for tool #{tool.id}: #{e.message}"
  end

  # Extract description from HTML
  def extract_description(doc)
    # Try Open Graph description first
    og_desc = doc.at_css('meta[property="og:description"]')&.[]('content')
    return og_desc.strip if og_desc.present? && og_desc.strip.length > 20

    # Try Twitter card description
    twitter_desc = doc.at_css('meta[name="twitter:description"]')&.[]('content')
    return twitter_desc.strip if twitter_desc.present? && twitter_desc.strip.length > 20

    # Try meta description
    meta_desc = doc.at_css('meta[name="description"]')&.[]('content')
    return meta_desc.strip if meta_desc.present? && meta_desc.strip.length > 20

    # For GitHub repos, try the repository description
    github_desc = doc.at_css('p[class*="description"]')&.text&.strip
    return github_desc if github_desc.present? && github_desc.length > 20

    nil
  end

  # Extract icon/image URL from HTML
  def extract_icon_url(doc, base_url)
    # Try Open Graph image first
    og_image = doc.at_css('meta[property="og:image"]')&.[]('content')
    return absolute_url(og_image, base_url) if og_image.present?

    # Try Twitter card image
    twitter_image = doc.at_css('meta[name="twitter:image"]')&.[]('content')
    return absolute_url(twitter_image, base_url) if twitter_image.present?

    # For GitHub repos, try the repository avatar
    github_avatar = doc.at_css('img[alt*="avatar"]')&.[]('src')
    return absolute_url(github_avatar, base_url) if github_avatar.present?

    # Try favicon
    favicon = doc.at_css('link[rel="icon"]')&.[]('href')
    return absolute_url(favicon, base_url) if favicon.present?

    nil
  end

  # Validate that a string is a valid URL format
  def valid_url?(url_string)
    return false if url_string.blank?
    
    # Check for common invalid patterns (descriptive text, not URLs)
    invalid_patterns = [
      /^n\/a$/i,
      /^not available$/i,
      /^not.*identifiable/i,
      /^the official website/i,
      /^official website url/i,
      /^website.*not.*clearly/i
    ]
    
    return false if invalid_patterns.any? { |pattern| url_string.match?(pattern) }
    
    # Try to parse as URI to validate format
    uri = URI.parse(url_string)
    return false unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    
    # Check for fake/domain parking domains
    domain = uri.host&.downcase
    return false if domain.blank?
    
    # Blacklist known domain parking/fake domains
    fake_domains = %w[
      fakelink.com
      example.com
      placeholder.com
      domain.com
      hugedomains.com
      godaddy.com
      namecheap.com
      sedo.com
      afternic.com
    ]
    
    # Check if domain matches any fake domain (exact match or subdomain)
    if fake_domains.any? { |fake| domain == fake || domain.end_with?(".#{fake}") }
      Rails.logger.warn "Rejected fake/domain parking URL: #{url_string}"
      return false
    end
    
    # Check for domain parking indicators in the URL path
    # Many parking pages have paths like /for-sale, /buy-now, etc.
    parking_paths = %w[
      for-sale
      buy-now
      purchase
      domain-sale
      domain-for-sale
      this-domain
    ]
    
    if parking_paths.any? { |path| uri.path&.downcase&.include?(path) }
      Rails.logger.warn "Rejected URL with parking page indicators: #{url_string}"
      return false
    end
    
    true
  rescue URI::InvalidURIError
    false
  end

  # Convert relative URL to absolute URL
  def absolute_url(url, base_url)
    return nil if url.blank?

    return url if url.start_with?("http://", "https://")

    base_uri = URI.parse(base_url)
    URI.join(base_uri, url).to_s
  rescue URI::InvalidURIError
    nil
  end

  # Attach icon from URL using Active Storage
  def attach_icon_from_url(tool, icon_url)
    return if icon_url.blank?

    # Download the image
    response = Faraday.get(icon_url) do |req|
      req.headers["User-Agent"] = "HackerTools/1.0"
      req.options.timeout = 10
    end

    return unless response.success?

    # Check if it's actually an image
    content_type = response.headers["content-type"]
    return unless content_type&.start_with?("image/")

    # Determine file extension from content type
    extension = case content_type
                when /jpeg|jpg/ then "jpg"
                when /png/ then "png"
                when /gif/ then "gif"
                when /svg/ then "svg"
                when /webp/ then "webp"
                else "jpg" # Default fallback
                end

    # Attach to tool using Active Storage
    tool.icon.attach(
      io: StringIO.new(response.body),
      filename: "icon.#{extension}",
      content_type: content_type
    )

    Rails.logger.info "Attached icon from #{icon_url} to tool #{tool.id}"
  rescue StandardError => e
    Rails.logger.warn "Failed to attach icon from #{icon_url} to tool #{tool.id}: #{e.message}"
  end
end

