class AddReplyRepostQuoteFieldsToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :in_reply_to_post_id, :integer
    add_column :posts, :repost_of_post_id, :integer
    add_column :posts, :quote_of_post_id, :integer
  end
end
