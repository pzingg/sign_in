class ClearanceMailer < ActionMailer::Base
  cattr_accessor :host, :from

  default_url_options[:host] = ClearanceMailer.host

  def change_password(user)
    from       ClearanceMailer.from
    recipients user.email
    subject    "Change your password"
    body       :user => user
  end

  def confirmation(user)
    from       ClearanceMailer.from
    recipients user.email
    subject    "Account confirmation"
    body       :user => user
  end

end
