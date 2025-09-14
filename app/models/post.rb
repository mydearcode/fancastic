class Post < ApplicationRecord
  belongs_to :user
  
  # Self-referential associations for replies, reposts, and quotes
  belongs_to :in_reply_to_post, class_name: "Post", optional: true
  belongs_to :repost_of_post, class_name: "Post", optional: true
  belongs_to :quote_of_post, class_name: "Post", optional: true
  
  # Reverse associations
  has_many :replies, class_name: "Post", foreign_key: "in_reply_to_post_id", dependent: :destroy
  has_many :reposts, class_name: "Post", foreign_key: "repost_of_post_id", dependent: :destroy
  has_many :quotes, class_name: "Post", foreign_key: "quote_of_post_id", dependent: :destroy
  
  # Visibility enum
  enum :visibility, { everyone: 0, team_only: 1, followers: 2, only_me: 3 }
  
  # Validations
  validates :text, presence: true, unless: :is_repost?
  validates :visibility, presence: true
  
  # Scopes and helper methods
  scope :replies, -> { where.not(in_reply_to_post_id: nil) }
  scope :reposts, -> { where.not(repost_of_post_id: nil) }
  scope :quotes, -> { where.not(quote_of_post_id: nil) }
  scope :original_posts, -> { where(in_reply_to_post_id: nil, repost_of_post_id: nil, quote_of_post_id: nil) }
  
  def is_reply?
    in_reply_to_post_id.present?
  end
  
  def is_repost?
    repost_of_post_id.present? && text.blank?
  end
  
  def is_quote?
    quote_of_post_id.present? && text.present?
  end
end
