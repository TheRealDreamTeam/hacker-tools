class Tool < ApplicationRecord
  # Owned by a user; attachments hold icon/picture assets via Active Storage.
  belongs_to :user

  has_one_attached :icon
  has_one_attached :picture
end

