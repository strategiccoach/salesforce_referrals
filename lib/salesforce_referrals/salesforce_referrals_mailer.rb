if defined?(ActionMailer)
  class SalesforceReferralsMailer < ActionMailer::Base
    default from: 'Strategic Coach <webmaster@strategiccoach.com>'
    layout false
  
    def submission(referral)
      @referral = referral
      mail(to: "referrals@strategiccoach.com",subject: "Referral Submission",from: "clientsite@strategiccoach.com")
    end
    
    def errors(err, vars)
      @error = err
      @vars =  vars
      mail(to: "techlogger@strategiccoach.com",subject: "Error Reported with the SF Referral Integration")

      # # body = render_to_string(layout: false, template: "#{File.dirname(__FILE__)}/mailer/errors", locals: { :@error => err, @vars => vars })
      # mail(
      #   subject: "Error Reported with the SF Referral Integration", 
      #   to: "techlogger@strategiccoach.com", 
      #   from: "clientsite@strategiccoach.com",
      #   template_path:  "app/views/mailer",
      #   # template_name: "errors",
      #   layout: false,
      #   content_type: "text/html"
      # )
    end
  end
end