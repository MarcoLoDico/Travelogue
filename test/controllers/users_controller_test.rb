require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_user_path
    assert_response :success
    assert_select "h1", "Create Account"
    assert_select "input[name='user[email_address]']"
    assert_select "input[name='user[password]']"
    assert_select "input[name='user[password_confirmation]']"
  end

  test "should create new user with valid attributes" do
    assert_difference "User.count", 1 do
      post users_path, params: {
        user: {
          email_address: "newuser@example.com",
          password: "securepassword123",
          password_confirmation: "securepassword123"
        }
      }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert_select "h1", "My Travels"

    user = User.find_by(email_address: "newuser@example.com")
    assert_not_nil user
    assert user.authenticate("securepassword123")
  end

  test "should not create user with invalid email" do
    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          email_address: "invalid-email",
          password: "securepassword123",
          password_confirmation: "securepassword123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".bg-red-100"
  end

  test "should not create user with blank email" do
    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          email_address: "",
          password: "securepassword123",
          password_confirmation: "securepassword123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".bg-red-100"
  end

  test "should not create user with short password" do
    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          email_address: "newuser@example.com",
          password: "short",
          password_confirmation: "short"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".bg-red-100"
  end

  test "should not create user with mismatched password confirmation" do
    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          email_address: "newuser@example.com",
          password: "securepassword123",
          password_confirmation: "differentpassword"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".bg-red-100"
  end

  test "should normalize email address" do
    post users_path, params: {
      user: {
        email_address: "  TEST@EXAMPLE.COM  ",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }
    }

    assert_redirected_to root_path

    user = User.find_by(email_address: "test@example.com")
    assert_not_nil user
  end

  test "should not create user with duplicate email" do
    existing_user = users(:alice)

    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          email_address: existing_user.email_address,
          password: "securepassword123",
          password_confirmation: "securepassword123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".bg-red-100"
  end
end
