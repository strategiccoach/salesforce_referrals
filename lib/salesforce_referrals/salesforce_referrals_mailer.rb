if defined?(ActionMailer)
  class SalesforceReferralsMailer < ActionMailer::Base
    default from: 'Strategic Coach <webmaster@strategiccoach.com>'
    layout false
  
    def submission(referral)
      @referral = referral
      key = referral['source'].present? ? referral['source'] : ENV['SERVICE_IDENTIFIER'].to_s
      source = { "referral_sharecoach": "Share Coach", 
        "referral_introductions": "Introductions", 
        "referral_client": "Client Site"}[key.to_sym]
      mail(to: "referrals@strategiccoach.com", subject: "Referral Submission from #{source}",from: "clientsite@strategiccoach.com")
    end
    
    def errors(err, vars, data)
      @error = err
      @vars =  vars
      @data = data
      mail(to: "techlogger@strategiccoach.com",subject: "Error Reported with the SF Referral Integration")
    end
  end
end