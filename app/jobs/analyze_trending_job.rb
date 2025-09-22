class AnalyzeTrendingJob < ApplicationJob
  queue_as :default

  def perform
    # Collect posts from the last 1 hour
    recent_posts = Post.where(created_at: 1.hour.ago..Time.current)
                      .where.not(text: [nil, ''])
    
    return if recent_posts.empty?
    
    # Set up current window - use fixed hourly windows to prevent duplicates
    current_hour = Time.current.beginning_of_hour
    window_start = current_hour - 1.hour
    window_end = current_hour
    window_key = "1h"
    
    # Extract phrases and hashtags
    phrase_counts = Hash.new(0)
    
    recent_posts.find_each do |post|
      # Extract hashtags
      hashtags = post.text.scan(/#\w+/).map(&:downcase)
      hashtags.each { |tag| phrase_counts[tag] += 1 }
      
      # Extract mentions
      mentions = post.text.scan(/@\w+/).map(&:downcase)
      mentions.each { |mention| phrase_counts[mention] += 1 }
      
      # Extract words (excluding common stop words)
      words = post.text.downcase
                      .gsub(/[^\w\s#@]/, ' ')
                      .split
                      .reject { |word| stop_words.include?(word) }
                      .select { |word| word.length >= 3 }
      
      words.each { |word| phrase_counts[word] += 1 }
      
      # Extract bigrams (two-word phrases)
      words.each_cons(2) do |bigram|
        phrase = bigram.join(' ')
        phrase_counts[phrase] += 1 if phrase.length >= 6
      end
    end
    
    # Update or create TrendEntry records
    phrase_counts.each do |phrase, count|
      next if count < 2 # Only consider phrases that appear at least twice
      
      trend_entry = TrendEntry.find_or_initialize_by(
        phrase: phrase,
        window: window_key,
        window_start: window_start,
        window_end: window_end
      )
      
      trend_entry.count = count
      trend_entry.save!
    end
    
    # Clean up old trend entries (older than 24 hours)
    TrendEntry.where(window_start: ...24.hours.ago).delete_all
    
    # Clear cache to force refresh of trending list
    Rails.cache.delete("trending_topics_1h")
    
    # Broadcast updated trends via SolidCable
    trending_topics = TrendEntry.where(window: "1h")
                                .where(window_start: 1.hour.ago..Time.current)
                                .order(count: :desc)
                                .limit(10)
    
    ActionCable.server.broadcast("trends_channel", {
      action: "update_trends",
      html: ApplicationController.render(
        partial: "trends/list",
        locals: { trending_topics: trending_topics }
      )
    })
    
    Rails.logger.info "AnalyzeTrendingJob completed: processed #{recent_posts.count} posts, found #{phrase_counts.size} phrases"
  end
  
  private
  
  def stop_words
    %w[
      the and or but if then else when where what who how why
      is are was were be been being have has had do does did
      will would could should might may can cannot
      a an this that these those
      in on at by for with from to of
      i you he she it we they me him her us them
      my your his her its our their
      very really quite just only also too much many
      get got getting go goes going went gone
      say says said saying tell tells told telling
      know knows knew known knowing think thinks thought thinking
      see sees saw seen seeing look looks looked looking
      come comes came coming take takes took taken taking
      make makes made making give gives gave given giving
      want wants wanted wanting need needs needed needing
      like likes liked liking love loves loved loving
      good bad great nice cool awesome amazing
      big small large little huge tiny
      new old young first last next
      right wrong true false yes no
      here there now then today yesterday tomorrow
      about over under through around between among
      after before during while since until
      because since although though however therefore
      maybe perhaps probably definitely certainly
      some any all every each both either neither
      one two three four five six seven eight nine ten
      more most less least better best worse worst
      same different similar other another
    ]
  end
end
