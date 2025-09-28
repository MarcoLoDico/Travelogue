require "test_helper"

class OneTimeCodeMailerTest < ActionMailer::TestCase
  test "send_code" do
    user = users(:alice)
    code = "123456"

    mail = OneTimeCodeMailer.send_code(user, code)
    assert_equal "Your Travelogue login code", mail.subject
    assert_equal [ user.email_address ], mail.to
    assert_match code, mail.body.encoded
    assert_match "Here's your login code for Travelogue:", mail.body.encoded
  end
end
