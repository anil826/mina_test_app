class Micropost < ActiveRecord::Base
  belongs_to :user
  default_scope -> { order(created_at: :desc) }
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }
  mount_uploader :picture , PictureUploader
  validate :picture_size

  def picture_size
    if picture.size > 5.megabytes
      errors.add(:picture, "Picture must be less then 3 MB")
    end
  end
end
