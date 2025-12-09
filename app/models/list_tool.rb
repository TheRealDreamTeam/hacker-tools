class ListTool < ApplicationRecord
  belongs_to :list
  belongs_to :tool

  validates :list_id, uniqueness: { scope: :tool_id }
end

