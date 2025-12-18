# Prevent accidental asset precompilation in development
# In development, assets should always be compiled on-the-fly
# Precompilation should only happen in production or staging

if Rails.env.development?
  Rake::Task["assets:precompile"].clear
  
  namespace :assets do
    desc "Asset precompilation is disabled in development - assets compile on-the-fly"
    task :precompile do
      puts "\n⚠️  WARNING: Asset precompilation is disabled in development!"
      puts "   Assets are compiled on-the-fly automatically."
      puts "   If you need to precompile assets, use: RAILS_ENV=production rails assets:precompile"
      puts "   To clear any existing precompiled assets: rails assets:clobber\n"
    end
  end
end

