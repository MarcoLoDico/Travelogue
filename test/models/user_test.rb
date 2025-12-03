require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      username: "test_user",
      email_address: "test@example.com",
      password: "securepassword123",
      password_confirmation: "securepassword123"
    )
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email address" do
    @user.email_address = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email_address], "can't be blank"
  end

  test "should require valid email format" do
    @user.email_address = "invalid-email"
    assert_not @user.valid?
    assert_includes @user.errors[:email_address], "is invalid"
  end

  test "should require unique email address" do
    duplicate_user = @user.dup
    @user.save!
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email_address], "has already been taken"
  end

  test "should normalize email address" do
    @user.email_address = "  TEST@EXAMPLE.COM  "
    @user.save!
    assert_equal "test@example.com", @user.email_address
  end

  test "should require password" do
    @user.password = nil
    @user.password_confirmation = nil
    assert_not @user.valid?
    assert_includes @user.errors[:password], "can't be blank"
  end

  test "should require password minimum length" do
    @user.password = "short"
    @user.password_confirmation = "short"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "should authenticate with correct password" do
    @user.save!
    assert @user.authenticate("securepassword123")
  end

  test "should not authenticate with incorrect password" do
    @user.save!
    assert_not @user.authenticate("wrongpassword")
  end

  test "should have many sessions" do
    @user.save!
    session = @user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1")

    assert_includes @user.sessions, session
  end

  test "should have many visits" do
    @user.save!
    place = Place.create!(name: "Test Place", kind: 1, country_code: "US")
    visit = @user.visits.create!(place: place, visited_on: Date.current)

    assert_includes @user.visits, visit
  end

  test "should have many places through visits" do
    @user.save!
    place = Place.create!(name: "Test Place", kind: 1, country_code: "US")
    @user.visits.create!(place: place, visited_on: Date.current)

    assert_includes @user.places, place
  end

  test "should destroy dependent records when deleted" do
    @user.save!
    place = Place.create!(name: "Test Place", kind: 1, country_code: "US")
    visit = @user.visits.create!(place: place, visited_on: Date.current)
    session = @user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1")

    @user.destroy

    assert_raises(ActiveRecord::RecordNotFound) { visit.reload }
    assert_raises(ActiveRecord::RecordNotFound) { session.reload }
  end
end
