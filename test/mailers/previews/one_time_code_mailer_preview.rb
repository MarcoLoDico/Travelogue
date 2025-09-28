# Preview all emails at http://localhost:3000/rails/mailers/one_time_code_mailer
class OneTimeCodeMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/one_time_code_mailer/send_code
  def send_code
    OneTimeCodeMailer.send_code
  end
end
