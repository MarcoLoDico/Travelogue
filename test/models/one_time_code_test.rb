require "test_helper"

class OneTimeCodeTest < ActiveSupport::TestCase
  def setup
    @user = users(:alice)
    @code = OneTimeCode.new(
      user: @user,
      code: "123456",
      expires_at: 15.minutes.from_now
    )
  end

  test "should be valid with valid attributes" do
    assert @code.valid?
  end

  test "should require user" do
    @code.user = nil
    assert_not @code.valid?
    assert_includes @code.errors[:user], "must exist"
  end

  test "should require code" do
    @code.code = nil
    assert_not @code.valid?
    assert_includes @code.errors[:code], "can't be blank"
  end

  test "should require code to be exactly 6 digits" do
    @code.code = "12345"
    assert_not @code.valid?
    assert_includes @code.errors[:code], "is the wrong length (should be 6 characters)"

    @code.code = "1234567"
    assert_not @code.valid?
    assert_includes @code.errors[:code], "is the wrong length (should be 6 characters)"

    @code.code = "123456"
    assert @code.valid?
  end

  test "should require expires_at" do
    @code.expires_at = nil
    assert_not @code.valid?
    assert_includes @code.errors[:expires_at], "can't be blank"
  end

  test "should be expired when expires_at is in the past" do
    @code.expires_at = 1.hour.ago
    assert @code.expired?
  end

  test "should not be expired when expires_at is in the future" do
    @code.expires_at = 1.hour.from_now
    assert_not @code.expired?
  end

  test "should be valid when not used and not expired" do
    @code.used = false
    @code.expires_at = 1.hour.from_now
    assert @code.still_valid?
  end

  test "should not be valid when used" do
    @code.used = true
    @code.expires_at = 1.hour.from_now
    assert_not @code.still_valid?
  end

  test "should not be valid when expired" do
    @code.used = false
    @code.expires_at = 1.hour.ago
    assert_not @code.still_valid?
  end

  test "should mark as used" do
    @code.save!
    @code.use!
    assert @code.used?
  end

  test "should generate code for user" do
    code = OneTimeCode.generate_for(@user)

    assert_not_nil code
    assert_equal @user, code.user
    assert_equal 6, code.code.length
    assert code.code.match?(/\A\d{6}\z/)
    assert_not code.used?
    assert code.expires_at > 14.minutes.from_now
    assert code.expires_at < 16.minutes.from_now
  end

  test "should clean up old codes when generating new one" do
    # Create an expired code
    old_code = @user.one_time_codes.create!(
      code: "111111",
      expires_at: 1.hour.ago,
      used: false
    )

    # Generate new code
    new_code = OneTimeCode.generate_for(@user)

    # Old code should be destroyed
    assert_raises(ActiveRecord::RecordNotFound) { old_code.reload }
    assert_equal new_code, @user.one_time_codes.last
  end

  test "should not clean up valid codes when generating new one" do
    # Create a valid code
    valid_code = @user.one_time_codes.create!(
      code: "222222",
      expires_at: 1.hour.from_now,
      used: false
    )

    # Generate new code
    new_code = OneTimeCode.generate_for(@user)

    # Valid code should still exist
    assert valid_code.reload
    assert_equal 3, @user.one_time_codes.count # 2 from fixtures + 1 new
  end

  test "valid scope should return only valid codes" do
    valid_code = @user.one_time_codes.create!(
      code: "333333",
      expires_at: 1.hour.from_now,
      used: false
    )

    expired_code = @user.one_time_codes.create!(
      code: "444444",
      expires_at: 1.hour.ago,
      used: false
    )

    used_code = @user.one_time_codes.create!(
      code: "555555",
      expires_at: 1.hour.from_now,
      used: true
    )

    valid_codes = OneTimeCode.valid
    assert_includes valid_codes, valid_code
    assert_not_includes valid_codes, expired_code
    assert_not_includes valid_codes, used_code
  end

  test "expired scope should return only expired codes" do
    valid_code = @user.one_time_codes.create!(
      code: "666666",
      expires_at: 1.hour.from_now,
      used: false
    )

    expired_code = @user.one_time_codes.create!(
      code: "777777",
      expires_at: 1.hour.ago,
      used: false
    )

    expired_codes = OneTimeCode.expired
    assert_not_includes expired_codes, valid_code
    assert_includes expired_codes, expired_code
  end
end
