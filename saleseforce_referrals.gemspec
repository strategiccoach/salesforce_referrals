Gem::Specification.new do |s|
  s.name        = 'salesforce_referrals'
  s.version     = '0.0.1'
  s.date        = '2021-01-20'
  s.summary     = "Salesforce Referrals Integration"
  s.description = "Push incoming referrals to a Salesforce API endpoint for automated integration"
  s.authors     = ["Paul Devisser"]
  s.email       = 'paul.devisser@strategiccoach.com'
  s.files       = [
    "lib/salesforce_referrals.rb", 
    "app/jobs/salesforce_referrals_job.rb",
    "app/mailers/salesforce_referral_error_mailer.rb",
    "app/views/salesforce_referrals_error_mailer/error.html.erb"
  ]
  s.homepage    =
    ''
  s.license       = 'MIT'
end