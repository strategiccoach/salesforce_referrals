class SendReferralsMailer < ApplicationMailer

  def submission(referral)
    @referral = referral
    mail(to: "referrals@strategiccoach.com", subject: "Referral Submission")
  end
end
