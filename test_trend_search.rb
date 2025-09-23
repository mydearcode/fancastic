#!/usr/bin/env ruby

puts "=== POST ARAMA TESTİ ==="

phrase = "alex'i özleyenler kulübü"
puts "Aranan phrase: #{phrase.inspect}"

# TrendsController'daki arama mantığını simüle et
normalized_phrase = phrase.downcase.gsub(/([\p{L}]+)'([\p{L}]+)/, '\1\2').strip
puts "Normalized phrase: #{normalized_phrase.inspect}"

# Arama patternları oluştur
patterns = [phrase.downcase, normalized_phrase, "##{phrase.downcase}", "##{normalized_phrase}"].uniq
puts "Search patterns: #{patterns.inspect}"

# Post arama sorgusu
posts_query = Post.includes(:user).where.not(text: [nil, ''])

conditions = patterns.map { |pattern| "LOWER(text) LIKE LOWER(?)" }
query_params = patterns.map { |pattern| "%#{pattern}%" }

puts "\nSQL Query conditions: #{conditions.join(' OR ')}"
puts "Query params: #{query_params.inspect}"

matching_posts = posts_query.where(
  conditions.join(' OR '), 
  *query_params
)

puts "\n=== SONUÇLAR ==="
puts "Bulunan post sayısı: #{matching_posts.count}"

if matching_posts.any?
  puts "\nBulunan postlar:"
  matching_posts.limit(5).each_with_index do |post, index|
    puts "#{index + 1}. Post ID: #{post.id}"
    puts "   Text: #{post.text.inspect}"
    puts "   User: #{post.user&.username || 'N/A'}"
    puts "   Created: #{post.created_at}"
    puts "---"
  end
else
  puts "\n❌ Hiç post bulunamadı!"
  
  # Tüm postları kontrol et
  all_posts = Post.where.not(text: [nil, ''])
  puts "\nToplam post sayısı: #{all_posts.count}"
  
  # Alex içeren postları ara
  alex_posts = all_posts.where("LOWER(text) LIKE ?", "%alex%")
  puts "Alex içeren post sayısı: #{alex_posts.count}"
  
  if alex_posts.any?
    puts "\nAlex içeren postlar:"
    alex_posts.limit(3).each do |post|
      puts "- #{post.text.inspect}"
    end
  end
  
  # Özleyenler içeren postları ara
  ozleyenler_posts = all_posts.where("LOWER(text) LIKE ?", "%özleyenler%")
  puts "\nÖzleyenler içeren post sayısı: #{ozleyenler_posts.count}"
  
  if ozleyenler_posts.any?
    puts "\nÖzleyenler içeren postlar:"
    ozleyenler_posts.limit(3).each do |post|
      puts "- #{post.text.inspect}"
    end
  end
end