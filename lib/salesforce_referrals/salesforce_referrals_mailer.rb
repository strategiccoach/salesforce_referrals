if defined?(ActionMailer)
  class SalesforceReferrals::Mailer < ActionMailer::Base
    layout false
  
    def submission(referral)
      headers = {
        subject: "Referral Submission",
        to: "referrals@strategiccoach.com",
        from: "clientsite@strategiccoach.com",
        reply_to: "clientsite@strategiccoach.com",
        template_path: "#{File.dirname(__FILE__)}",
        template_name: 'submission',
        layout: false,
        content_type: "text/html"
      }

      @referral = referral
      mail headers
    end
    
    def errors(err, vars)
      headers = {
        subject: "Error Reported with the SF Referral Integration",
        to: "techlogger@strategiccoach.com",
        from: "clientsite@strategiccoach.com",
        reply_to: "clientsite@strategiccoach.com",
        # template_path: "#{File.dirname(__FILE__)}/mailer",
        # template_name: 'errors',
        # layout: false,
        # content_type: "text/html"
      }
      Rails.logger.info "#{File.dirname(__FILE__)}"

      Rails.logger.info "H: #{headers}"
      @error = err
      @vars =  vars
      mail headers
    end
  end
end