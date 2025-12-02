# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create a test user
email = ENV.fetch("TEST_USER_EMAIL", "demo@travelogue.dev")
password = ENV.fetch("TEST_USER_PASSWORD", "password123")

user = User.find_or_initialize_by(email_address: email)
if user.new_record?
  user.password = password
  user.password_confirmation = password
  user.save!
  puts "Created user: #{user.email_address}"
else
  puts "User already exists: #{user.email_address}"
end

# Create Toronto place
toronto = Place.find_or_create_by!(name: "Toronto") do |p|
  p.kind = 1
  p.country_code = "CA"
  p.admin1_code = "ON"
  p.lat = 43.6532
  p.lon = -79.3832
  p.population = 2930000
end

# Create a visit record for the user to Toronto
visit = Visit.find_or_create_by!(user: user, place: toronto) do |v|
  v.visited_on = Date.current - 30.days
  v.arrived_at = 30.days.ago.beginning_of_day + 14.hours
  v.departed_at = 29.days.ago.beginning_of_day + 10.hours
  v.notes = "Amazing city! Loved the CN Tower and the waterfront. Great food scene and friendly people."
  v.lat = 43.6532
  v.lon = -79.3832
  v.source = "manual"
end

puts "Seed data created successfully!"
puts "User: #{user.email_address} (password: #{password})"
puts "Place: #{toronto.name}"
puts "Visit: #{visit.visited_on}"
