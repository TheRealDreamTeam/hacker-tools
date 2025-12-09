class ToolTag < ApplicationRecord
  belongs_to :tool
  belongs_to :tag

  validates :tool_id, uniqueness: { scope: :tag_id }
end

