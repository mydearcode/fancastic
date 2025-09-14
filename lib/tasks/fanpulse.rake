namespace :fanpulse do
  desc "Restore daily energy for all users"
  task restore_daily_energy: :environment do
    puts "Starting daily energy restoration..."
    
    User.find_each do |user|
      # Log the energy restoration
      FanPulse::InteractionLog.log_interaction(user, 'daily_restore')
      puts "Restored energy for user: #{user.username} (#{user.energy}/100)"
    end
    
    puts "Daily energy restoration completed!"
  end
  
  desc "Show energy statistics"
  task energy_stats: :environment do
    total_users = User.count
    low_energy_users = User.where('energy < ?', 20).count
    full_energy_users = User.where(energy: 100).count
    avg_energy = User.average(:energy).to_f.round(2)
    
    puts "=== FanPulse Energy Statistics ==="
    puts "Total Users: #{total_users}"
    puts "Average Energy: #{avg_energy}/100"
    puts "Low Energy Users (<20): #{low_energy_users}"
    puts "Full Energy Users (100): #{full_energy_users}"
    puts "Recent Interactions: #{FanPulse::InteractionLog.where('created_at > ?', 24.hours.ago).count}"
  end
end