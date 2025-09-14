namespace :admin do
  desc "Make a user an admin by username"
  task :make_user, [:username] => :environment do |task, args|
    username = args[:username]
    
    if username.blank?
      puts "Usage: rails admin:make_user[username]"
      puts "Example: rails admin:make_user[john_doe]"
      exit 1
    end
    
    user = User.find_by(username: username)
    
    if user.nil?
      puts "❌ User with username '#{username}' not found."
      puts "Available users: #{User.pluck(:username).join(', ')}"
      exit 1
    end
    
    if user.admin?
      puts "✅ User '#{username}' is already an admin."
    else
      user.update!(role: 'admin')
      puts "✅ User '#{username}' has been made an admin!"
    end
  end
  
  desc "List all admin users"
  task :list => :environment do
    admins = User.where(role: 'admin')
    
    if admins.empty?
      puts "❌ No admin users found."
      puts "Create an admin with: rails admin:make_user[username]"
    else
      puts "👑 Admin Users:"
      admins.each do |admin|
        puts "  - #{admin.username} (#{admin.email_address})"
      end
    end
  end
  
  desc "Remove admin privileges from a user"
  task :remove_user, [:username] => :environment do |task, args|
    username = args[:username]
    
    if username.blank?
      puts "Usage: rails admin:remove_user[username]"
      exit 1
    end
    
    user = User.find_by(username: username)
    
    if user.nil?
      puts "❌ User with username '#{username}' not found."
      exit 1
    end
    
    if user.admin?
      user.update!(role: 'user')
      puts "✅ Admin privileges removed from '#{username}'."
    else
      puts "ℹ️ User '#{username}' is not an admin."
    end
  end
end