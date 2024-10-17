class ApplicationMailer < ActionMailer::Base
  default from: 'product@nirmaan.ai'
  layout 'mailer'
  helper :application

  def password_reset_request request, first_name, email
    @password_reset_request = request
    subject = "Request to reset your password"
    mail(to: email, subject: subject, bcc: bcc_recipients)
  end

  def reset_password_confirmation_email first_name, email
    subject = "Your password has been reset"
    mail(to: email, subject: subject, bcc: bcc_recipients)
  end

  def send_mail_with_body subject, body, email
    mail(to: email, subject: subject, content_type: "text/html", body: body)
  end

  def bcc_recipients
    "product@recess.is, 46e2fe7221cf4c61ab1d116fcb7725cb@inbox.prosperworks.com"
  end

  def cc_recipients_for_event event
    event.supplier.organizers.map(&:email).join ","
  end

  def cc_recipients_for_offer offer
    offer.sponsor.brand_reps.map(&:email).join ","
  end

  def recipients_for_event event
    ApplicationMailer.owner_for_event(event).email
  end

  def recipients_for_offer offer
    ApplicationMailer.owner_for_offer(offer).email
  end

  def self.owner_for_event event
    event.owner || event.event_set.owner || event.supplier.organizers.nin(email: ['', nil]).first
  end

  def self.owner_for_offer offer
    offer.owner || offer.campaign.owner || offer.sponsor.brand_reps.nin(email: ['', nil]).first
  end
end
