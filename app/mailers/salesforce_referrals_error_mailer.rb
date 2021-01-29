class SalesforceReferralErrorMailer < ActionMailer::Base
  layout false
  default :from => "clintsite@strategiccoach.com", :content_type => "text/html"
  
  def errors(err, vars)
    @error = err
    @vars =  vars
    mail(to: "techlogger@strategiccoach.com", subject: "Error Reported with the SF Referral Integration")
  end
end