# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create a test user
user = User.find_or_create_by!(email_address: ENV["TEST_USER_EMAIL"]) do |u|
  u.password = "test"
  u.password_confirmation = "test"
end

# Create Toronto place
toronto = Place.find_or_create_by!(name: "Toronto") do |p|
  p.kind = 1  # Assuming 1 is for city
  p.country_code = "CA"
  p.admin1_code = "ON"
  p.lat = 43.6532
  p.lon = -79.3832
  p.population = 2930000
end

# Create a visit record for the user to Toronto
visit = Visit.find_or_create_by!(user: user, place: toronto) do |v|
  v.visited_on = Date.current - 30.days  # Visited 30 days ago
  v.arrived_at = 30.days.ago.beginning_of_day + 14.hours  # Arrived at 2 PM
  v.departed_at = 29.days.ago.beginning_of_day + 10.hours  # Left at 10 AM next day
  v.notes = "Amazing city! Loved the CN Tower and the waterfront. Great food scene and friendly people."
  v.lat = 43.6532
  v.lon = -79.3832
  v.source = "manual"
end

puts "Seed data created successfully!"
puts "User: #{user.email_address}"
puts "Place: #{toronto.name}"
puts "Visit: #{visit.visited_on}"
