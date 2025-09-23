class AnalyzeTrendingJob < ApplicationJob
  queue_as :default

  def perform
    # Collect posts from the last 30 minutes (broader analysis window)
    recent_posts = Post.where(created_at: 30.minutes.ago..Time.current)
                      .where.not(text: [nil, ''])
    
    Rails.logger.info "AnalyzeTrendingJob started: analyzing #{recent_posts.count} posts from last 30 minutes"
    
    return if recent_posts.empty?
    
    # Set up current window - use 15-minute windows for better trend detection
    current_time = Time.current
    window_start = current_time.beginning_of_hour + ((current_time.min / 15) * 15).minutes
    window_end = window_start + 15.minutes
    window_key = "15min"
    
    Rails.logger.info "Window: #{window_start} - #{window_end}"
    
    # Extract phrases and hashtags
    phrase_counts = Hash.new(0)
    
    recent_posts.find_each do |post|
      # Extract hashtags (Unicode-aware for Turkish characters) - PRESERVE ORIGINAL CASE
      hashtags = post.text.scan(/#[\p{L}\p{N}_]+/u)
      hashtags.each { |tag| phrase_counts[tag] += 1 }
      
      # Extract mentions (Unicode-aware for Turkish characters) - PRESERVE ORIGINAL CASE
      mentions = post.text.scan(/@[\p{L}\p{N}_]+/u)
      mentions.each { |mention| phrase_counts[mention] += 1 }
      
      # Extract abbreviations (2+ uppercase letters) - PRESERVE ORIGINAL CASE
      abbreviations = post.text.scan(/\b[A-ZÇĞIÖŞÜ]{2,}\b/)
      abbreviations.each { |abbr| phrase_counts[abbr] += 1 }
      
      # Extract words (excluding common stop words) - Unicode-aware with improved processing
      # PRESERVE ORIGINAL CASE for trend phrases
      
      # Orijinal kelimeleri çıkar (apostroflu hallerini koruyarak ve CASE'i koruyarak)
      original_text = post.text.gsub(/[^\p{L}\p{N}\s#@']/u, ' ')
      original_words = original_text.split
                                  .reject { |word| stop_words.include?(word.gsub("'", "").downcase) }
                                  .select { |word| word.gsub("'", "").length >= 2 }
      
      # Normalize edilmiş kelimeler (sadece arama için, trend kaydetmede kullanılmayacak)
      processed_text = post.text.downcase
                              .gsub(/([\p{L}]+)'([\p{L}]+)/, '\1\2') # Connect apostrophe words: "Kurulu'nda" -> "kurulunda"
                              .gsub(/[^\p{L}\p{N}\s#@]/u, ' ')
      words = processed_text.split
                           .reject { |word| stop_words.include?(word) }
                           .select { |word| word.length >= 2 }
      
      # Use original words for trend phrases to preserve case
      all_words = (abbreviations + original_words).uniq
      
      # Tek kelimeler (1-gram) - sadece anlamlı olanları
      all_words.each do |word|
        # Tek kelime için daha sıkı filtre - en az 3 karakter ve stop word olmamalı
        next if word.gsub("'", "").length < 3
        next if stop_words.include?(word.gsub("'", "").downcase)
        phrase_counts[word] += 1
      end
      
      # Extract bigrams (two-word phrases) with better filtering
      # Use original words to preserve case
      original_words.each_cons(2) do |bigram|
        phrase = bigram.join(' ')
        # More selective bigram filtering - avoid meaningless combinations
        next if phrase.gsub("'", "").length < 6
        next if bigram.any? { |word| word.gsub("'", "").length < 2 }
        phrase_counts[phrase] += 1
      end
      
      # Extract trigrams (three-word phrases) for better context
      # Use original words to preserve case
      original_words.each_cons(3) do |trigram|
        phrase = trigram.join(' ')
        # Only include trigrams that are substantial and meaningful
        next if phrase.gsub("'", "").length < 12
        next if trigram.any? { |word| word.gsub("'", "").length < 2 }
        phrase_counts[phrase] += 1
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
