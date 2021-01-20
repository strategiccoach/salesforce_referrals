class SalesForceReferralErrorMailer < ActionMailer::Base
  layout false
  default :from => "clintsite@strategiccoach.com", :content_type => "text/html"
  
  def errors(err)
    mail(to: "techlogger@strategiccoach.com", subject: "Error Reported with the SF Referral Integration")
  end
end