class AnalyzeTrendingJob < ApplicationJob
  queue_as :default

  def perform
    # Collect posts from the last 30 minutes (broader analysis window)
    recent_posts = Post.where(created_at: 30.minutes.ago..Time.current)
                      .where.not(text: [nil, ''])
    
    Rails.logger.info "AnalyzeTrendingJob started: analyzing #{recent_posts.count} posts from last 30 minutes"
    
    return if recent_posts.empty?
    
    # Set up current window - use 30-minute windows for better trend detection
    current_time = Time.current
    window_start = current_time.beginning_of_hour + ((current_time.min / 30) * 30).minutes
    window_end = window_start + 30.minutes
    window_key = "30min"
    
    Rails.logger.info "Window: #{window_start} - #{window_end}"
    
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
    
    Rails.logger.info "Found #{phrase_counts.size} unique phrases"
    
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
      
      Rails.logger.info "Saved trend: #{phrase} (#{count} occurrences)"
    end
    
    # Clean up old trend entries (older than 24 hours)
    deleted_count = TrendEntry.where(window_start: ...24.hours.ago).delete_all
    Rails.logger.info "Cleaned up #{deleted_count} old trend entries"
    
    # Clear cache to force refresh of trending list
    Rails.cache.delete("trending_topics_15min")
    Rails.cache.delete("trending_topics_1h")
    
    # Broadcast updated trends via SolidCable
    trending_topics = TrendEntry.where(window: "15min")
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
    
    Rails.logger.info "AnalyzeTrendingJob completed: processed #{recent_posts.count} posts, found #{phrase_counts.size} phrases, saved #{phrase_counts.select { |_, count| count >= 2 }.size} trends"
  end
  
  private
  
  def stop_words
    %w[
      the and or but for with from this that these those
      bir bir bir bir bir bir bir bir bir bir
      ve ya da ama için ile den bu şu bunlar şunlar
      is are was were been being have has had
      will would could should might may can
      to at in on by of as
      i you he she it we they me him her us them
      my your his her its our their
      a an some any all each every
      not no never nothing none
      very much more most less least
      good bad better worse best worst
      big small large little
      new old young
      here there where when why how what who
      said says say tell told
      get got give gave take took
      go went come came
      see saw look looked
      know knew think thought
      want wanted need needed
      make made do did
      work worked
      time times
      way ways
      day days
      year years
      man men woman women
      child children
      life lives
      world
      country countries
      state states
      city cities
      home house
      school schools
      job jobs
      money
      family families
      friend friends
      people person
      group groups
      company companies
      government
      system systems
      program programs
      question questions
      problem problems
      service services
      place places
      case cases
      part parts
      number numbers
      week weeks
      month months
      hour hours
      minute minutes
      second seconds
      today yesterday tomorrow
      now then
      yes no
      right left
      up down
      over under
      before after
      during while
      because since
      if when
      so too also
      just only
      still yet
      again back
      away off
      out into
      about around
      between among
      through across
      against without
      within outside
      inside
    ]
  end
end
