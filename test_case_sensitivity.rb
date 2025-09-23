puts "=== CASE SENSITIVITY SORUNU ANALİZİ ==="

# Veritabanındaki trendleri kontrol et
puts "1. Veritabanındaki trendler:"
TrendEntry.where("phrase ILIKE ?", "%alex%").limit(5).each do |trend|
  puts "   - #{trend.phrase.inspect} (count: #{trend.count})"
end

puts "\n2. Postlardaki metinler:"
Post.where("text ILIKE ?", "%alex%").limit(3).each do |post|
  puts "   - #{post.text.inspect}"
end

# Case sensitivity testi
puts "\n3. Case sensitivity testi:"
test_phrases = [
  "alex'i özleyenler kulübü",
  "Alex'i Özleyenler Kulübü", 
  "ALEX'İ ÖZLEYENLER KULÜBÜ"
]

test_phrases.each do |phrase|
  trend_count = TrendEntry.where("phrase = ?", phrase).count
  trend_ilike = TrendEntry.where("phrase ILIKE ?", phrase).count
  post_count = Post.where("text ILIKE ?", "%#{phrase}%").count
  
  puts "   Phrase: #{phrase.inspect}"
  puts "     Trend exact match: #{trend_count}"
  puts "     Trend ILIKE: #{trend_ilike}"
  puts "     Post ILIKE: #{post_count}"
  puts
end

# Sorunun kaynağını bul
puts "4. Sorunun kaynağı:"
first_trend = TrendEntry.first
first_post = Post.where("text ILIKE ?", "%alex%").first

puts "   - Trendler küçük harfle saklanıyor: #{first_trend&.phrase&.inspect}"
puts "   - Postlar büyük harfle: #{first_post&.text&.inspect}"
puts "   - TrendsController ILIKE kullanıyor ama yine de eşleşmiyor"

# Gerçek sorunu bul
puts "\n5. Gerçek sorun testi:"
alex_trend = TrendEntry.where("phrase ILIKE ?", "%alex%özleyenler%").first
if alex_trend
  puts "   Alex trendi bulundu: #{alex_trend.phrase.inspect}"
  
  # Bu trendin URL'ini oluştur
  encoded_url = ERB::Util.url_encode(alex_trend.phrase)
  puts "   Encoded URL: #{encoded_url}"
  
  # TrendsController'daki decode işlemini simüle et
  decoded_phrase = CGI.unescape(encoded_url)
  puts "   Decoded phrase: #{decoded_phrase.inspect}"
  
  # Normalize işlemini simüle et
  normalized = decoded_phrase.gsub(/[^\p{L}\p{N}\s]/u, '').squeeze(' ').strip.downcase
  puts "   Normalized: #{normalized.inspect}"
  
  # Post araması
  post_search_result = Post.where("text ILIKE ?", "%#{decoded_phrase}%").count
  puts "   Post arama sonucu: #{post_search_result} adet"
end