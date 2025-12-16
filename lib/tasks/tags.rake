namespace :tags do
  desc "Generate descriptions for tags with 'Auto-generated from submission' description"
  task generate_descriptions: :environment do
    puts "== Generating Tag Descriptions =="
    puts ""

    tags = Tag.where(tag_description: "Auto-generated from submission")
    total = tags.count
    puts "Found #{total} tags to update"
    puts ""

    if total == 0
      puts "No tags to update. Exiting."
      next
    end

    updated_count = 0
    failed_count = 0

    tags.find_each.with_index do |tag, index|
      print "[#{index + 1}/#{total}] Generating description for '#{tag.tag_name}' (#{tag.tag_type})... "

      begin
        # Generate description using RubyLLM
        description = generate_tag_description(tag)
        
        if description.present?
          tag.update!(tag_description: description)
          puts "✓ Updated"
          updated_count += 1
        else
          puts "✗ Failed (no description generated)"
          failed_count += 1
        end
      rescue StandardError => e
        puts "✗ Error: #{e.message}"
        Rails.logger.error "Failed to generate description for tag #{tag.id} (#{tag.tag_name}): #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n")
        failed_count += 1
      end

      # Add a small delay to avoid rate limiting
      sleep(0.5) if index < total - 1
    end

    puts ""
    puts "== Summary =="
    puts "Total tags: #{total}"
    puts "Updated: #{updated_count}"
    puts "Failed: #{failed_count}"
    puts ""
    puts "Done!"
  end
end

# Helper methods for tag description generation
def generate_tag_description(tag)
  context = build_tag_description_context(tag)
  
  # Use gpt-4o for generating descriptions
  chat = RubyLLM.chat(model: "gpt-4o")
  
  # Ask for a description (1-2 sentences, clear and informative)
  response = chat.ask(context)
  
  # Extract the description from the response
  description = response.content.to_s.strip
  
  # Validate the description (should be meaningful, not empty or too short)
  if description.present? && description.length > 10
    description
  else
    nil
  end
rescue StandardError => e
  Rails.logger.error "Error generating description for tag #{tag.id}: #{e.message}"
  nil
end

# Build context for tag description generation
def build_tag_description_context(tag)
  "You are an expert at writing clear, concise descriptions for technical tags.\n\n" \
  "Generate a brief, informative description (1-2 sentences) for the following tag:\n\n" \
  "Tag Name: #{tag.tag_name}\n" \
  "Tag Type: #{tag.tag_type}\n" \
  "#{"Tag Type Slug: #{tag.tag_type_slug}\n" if tag.tag_type_slug.present?}" \
  "#{"Parent Tag: #{tag.parent.tag_name}\n" if tag.parent.present?}" \
  "\n" \
  "Requirements:\n" \
  "- The description should be clear and informative (1-2 sentences)\n" \
  "- Explain what the tag represents and its relevance\n" \
  "- Be specific and avoid generic phrases like 'A tag for X' or 'Related to X'\n" \
  "- Focus on what the tag means in a technical context\n" \
  "- If it's a programming language, explain what it's used for\n" \
  "- If it's a framework, explain what it does\n" \
  "- If it's a platform, explain what it provides\n" \
  "- If it's a content type, explain what kind of content it represents\n\n" \
  "Return only the description text, nothing else."
end

