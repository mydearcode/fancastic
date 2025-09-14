# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create Countries
england = Country.find_or_create_by!(name: "England") do |country|
  country.flag_url = "https://flagcdn.com/w320/gb-eng.png"
  country.color_primary = "#FF1744"
  country.color_secondary = "#FFFFFF"
end

spain = Country.find_or_create_by!(name: "Spain") do |country|
  country.flag_url = "https://flagcdn.com/w320/es.png"
  country.color_primary = "#AA151B"
  country.color_secondary = "#F1BF00"
end

germany = Country.find_or_create_by!(name: "Germany") do |country|
  country.flag_url = "https://flagcdn.com/w320/de.png"
  country.color_primary = "#000000"
  country.color_secondary = "#DD0000"
end

# Create Leagues
premier_league = League.find_or_create_by!(name: "Premier League", country: england)
la_liga = League.find_or_create_by!(name: "La Liga", country: spain)
bundesliga = League.find_or_create_by!(name: "Bundesliga", country: germany)

# Create Teams
# Premier League Teams
Team.find_or_create_by!(name: "Manchester United", league: premier_league, country: england) do |team|
  team.symbol_slug = "MUN"
  team.color_primary = "#DA020E"
  team.color_secondary = "#FBE122"
end

Team.find_or_create_by!(name: "Liverpool", league: premier_league, country: england) do |team|
  team.symbol_slug = "LIV"
  team.color_primary = "#C8102E"
  team.color_secondary = "#F6EB61"
end

Team.find_or_create_by!(name: "Arsenal", league: premier_league, country: england) do |team|
  team.symbol_slug = "ARS"
  team.color_primary = "#EF0107"
  team.color_secondary = "#9C824A"
end

# La Liga Teams
Team.find_or_create_by!(name: "Real Madrid", league: la_liga, country: spain) do |team|
  team.symbol_slug = "RMA"
  team.color_primary = "#FEBE10"
  team.color_secondary = "#00529F"
end

Team.find_or_create_by!(name: "FC Barcelona", league: la_liga, country: spain) do |team|
  team.symbol_slug = "BAR"
  team.color_primary = "#A50044"
  team.color_secondary = "#004D98"
end

# Bundesliga Teams
Team.find_or_create_by!(name: "Bayern Munich", league: bundesliga, country: germany) do |team|
  team.symbol_slug = "BAY"
  team.color_primary = "#DC052D"
  team.color_secondary = "#0066B2"
end

Team.find_or_create_by!(name: "Borussia Dortmund", league: bundesliga, country: germany) do |team|
  team.symbol_slug = "BVB"
  team.color_primary = "#FDE100"
  team.color_secondary = "#000000"
end

# Create sample users and posts for testing
if User.count == 0
  # Create sample users
  user1 = User.create!(
    email_address: "fan1@example.com",
    password: "password123",
    username: "football_fan",
    team: Team.find_by(name: "Manchester United"),
    energy: 100,
    message_privacy: "everyone",
    role: "user"
  )

  user2 = User.create!(
    email_address: "fan2@example.com",
    password: "password123",
    username: "barca_lover",
    team: Team.find_by(name: "FC Barcelona"),
    energy: 100,
    message_privacy: "followers",
    role: "user"
  )

  user3 = User.create!(
    email_address: "admin@example.com",
    password: "password123",
    username: "admin_user",
    team: Team.find_by(name: "Real Madrid"),
    energy: 100,
    message_privacy: "everyone",
    role: "admin"
  )

  # Create sample posts
  Post.create!(
    user: user1,
    text: "What a match! Manchester United played brilliantly today! 🔴⚽",
    visibility: "everyone"
  )

  Post.create!(
    user: user2,
    text: "Barça's passing game is just poetry in motion. Visca el Barça! 💙❤️",
    visibility: "team_only"
  )

  Post.create!(
    user: user3,
    text: "Welcome to Fancastic! The ultimate platform for football fans worldwide! ⚽🌍",
    visibility: "everyone"
  )

  Post.create!(
    user: user1,
    text: "Can't wait for the next El Clasico! Who do you think will win?",
    visibility: "everyone"
  )

  Post.create!(
    user: user2,
    text: "Training hard pays off. Respect to all players giving their best! 💪",
    visibility: "followers"
  )

  puts "Created #{User.count} sample users and #{Post.count} sample posts."
  
  # Create sample conversations
  if Conversation.count == 0
    # Conversation between user1 and user2
    conversation1 = Conversation.create!(
      title: "Football Discussion",
      last_message_at: 2.hours.ago
    )
    
    conversation1.conversation_participants.create!(user: user1)
    conversation1.conversation_participants.create!(user: user2)
    
    conversation1.messages.create!(
      user: user1,
      content: "Hey! Did you see that amazing goal in yesterday's match?",
      created_at: 2.hours.ago
    )
    
    conversation1.messages.create!(
      user: user2,
      content: "Yes! Absolutely incredible technique. The way they curved that ball was pure magic! ⚽",
      created_at: 1.hour.ago
    )
    
    # Conversation between user1 and user3 (admin)
    conversation2 = Conversation.create!(
      last_message_at: 30.minutes.ago
    )
    
    conversation2.conversation_participants.create!(user: user1)
    conversation2.conversation_participants.create!(user: user3)
    
    conversation2.messages.create!(
      user: user3,
      content: "Welcome to Fancastic! Hope you're enjoying the platform so far.",
      created_at: 30.minutes.ago
    )
    
    puts "Created #{Conversation.count} sample conversations and #{Message.count} sample messages."
  end
end

puts "Seeded #{Country.count} countries, #{League.count} leagues, and #{Team.count} teams."
