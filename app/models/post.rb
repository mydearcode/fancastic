class Post < ApplicationRecord
  belongs_to :user
  
  # Active Storage attachment for images
  has_one_attached :image
  
  # Self-referential associations for replies, reposts, and quotes
  belongs_to :in_reply_to_post, class_name: "Post", optional: true
  belongs_to :repost_of_post, class_name: "Post", optional: true
  belongs_to :quote_of_post, class_name: "Post", optional: true
  
  # Reverse associations
  has_many :replies, class_name: "Post", foreign_key: "in_reply_to_post_id", dependent: :destroy
  has_many :reposts, class_name: "Post", foreign_key: "repost_of_post_id", dependent: :destroy
  has_many :quotes, class_name: "Post", foreign_key: "quote_of_post_id", dependent: :destroy
  
  # Likes association
  has_many :likes, dependent: :destroy
  has_many :liked_by_users, through: :likes, source: :user
  
  # Visibility enum
  enum :visibility, { everyone: 0, team_only: 1, followers: 2, only_me: 3 }
  
  # Validations
  validates :text, presence: true, unless: :is_repost_or_has_image?
  validates :visibility, presence: true
  validates :repost_of_post_id, uniqueness: { scope: :user_id, message: "You have already reposted this post" }, if: :is_repost?
  validate :image_format_and_size, if: -> { image.attached? }
  
  # Scopes and helper methods
  scope :replies, -> { where.not(in_reply_to_post_id: nil) }
  scope :reposts, -> { where.not(repost_of_post_id: nil) }
  scope :quotes, -> { where.not(quote_of_post_id: nil) }
  scope :original_posts, -> { where(in_reply_to_post_id: nil, repost_of_post_id: nil, quote_of_post_id: nil) }
  
  # Full-text search scope for post content
  scope :search_by_content, ->(query) {
    return none if query.blank?
    where("to_tsvector('english', text) @@ plainto_tsquery('english', ?)", query)
  }
  
  def is_reply?
    in_reply_to_post_id.present?
  end
  
  def is_repost?
    repost_of_post_id.present? && text.blank?
  end
  
  def is_quote?
    quote_of_post_id.present? && text.present?
  end
  
  def liked_by?(user)
    return false unless user
    likes.exists?(user: user)
  end
  
  def reposted_by?(user)
    return false unless user
    reposts.exists?(user: user)
  end

  def likes_count
    likes.count
  end

  def reposts_count
    # Combined count of reposts and quotes (Twitter/X style)
    reposts.count + quotes.count
  end

  def quotes_count
    quotes.count
  end

  def quotes_only_count
    # For quotes view page - only actual quotes
    quotes.count
  end

  def replies_count
    replies.count
  end

  private
  
  def is_repost_or_has_image?
    is_repost? || image.attached?
  end
  
  def image_format_and_size
    return unless image.attached?
    
    # Check file type
    unless image.content_type.in?(['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'])
      errors.add(:image, 'must be a JPEG, PNG, GIF, or WebP image')
    end
    
    # Check file size (max 10MB)
    if image.byte_size > 10.megabytes
      errors.add(:image, 'must be less than 10MB')
    end
  end
end
