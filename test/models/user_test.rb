require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(email_address: "test@example.com")
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email address" do
    @user.email_address = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email_address], "can't be blank"
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

  test "should find user by email for login" do
    @user.save!
    found_user = User.find_by_email_for_login("  TEST@EXAMPLE.COM  ")
    assert_equal @user, found_user
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

  test "should have many one time codes" do
    @user.save!
    code = @user.one_time_codes.create!(code: "123456", expires_at: 15.minutes.from_now)

    assert_includes @user.one_time_codes, code
  end

  test "should destroy dependent records when deleted" do
    @user.save!
    place = Place.create!(name: "Test Place", kind: 1, country_code: "US")
    visit = @user.visits.create!(place: place, visited_on: Date.current)
    session = @user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1")
    code = @user.one_time_codes.create!(code: "123456", expires_at: 15.minutes.from_now)

    @user.destroy

    assert_raises(ActiveRecord::RecordNotFound) { visit.reload }
    assert_raises(ActiveRecord::RecordNotFound) { session.reload }
    assert_raises(ActiveRecord::RecordNotFound) { code.reload }
  end
end
