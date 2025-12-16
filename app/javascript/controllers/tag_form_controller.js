import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tag-form"
// Auto-populates tag_type_id and tag_type_slug when tag_type is selected
export default class extends Controller {
  static targets = ["tagType", "tagTypeId", "tagTypeSlug", "tagTypeMappings"]

  connect() {
    // Initialize fields if tag_type is already set
    if (this.tagTypeTarget.value) {
      this.updateTagTypeFields()
    }
  }

  updateTagTypeFields() {
    const selectedTagType = this.tagTypeTarget.value
    if (!selectedTagType) return

    // Parse the tag type mappings from the data attribute
    const mappingsJson = this.tagTypeMappingsTarget.getAttribute("data-mappings")
    if (!mappingsJson) return

    const mappings = JSON.parse(mappingsJson)
    const mapping = mappings.find(m => m.tag_type === selectedTagType)

    if (mapping) {
      // Update hidden fields
      this.tagTypeIdTarget.value = mapping.tag_type_id
      this.tagTypeSlugTarget.value = mapping.tag_type_slug
    }
  }
}

