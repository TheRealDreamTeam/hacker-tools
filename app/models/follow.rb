class Follow < ApplicationRecord
  belongs_to :user
  belongs_to :followable, polymorphic: true

  validates :user_id, uniqueness: { scope: [:followable_type, :followable_id] }
end

