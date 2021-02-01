Gem::Specification.new do |s|
  s.name        = 'salesforce_referrals'
  s.version     = '0.0.1'
  s.date        = '2021-01-20'
  s.summary     = "Salesforce Referrals Integration"
  s.description = "Push incoming referrals to a Salesforce API endpoint for automated integration"
  s.authors     = ["Paul Devisser"]
  s.email       = 'paul.devisser@strategiccoach.com'
  s.files       = ['salesforce_referrals.gemspec', 'README.md', 
  'lib/salesforce_referrals.rb', 
  'lib/salesforce_referrals/salesforce_referrals.rb', 
  'lib/salesforce_referrals/salesforce_referrals_mailer.rb',
  'mailer/errors.html.erb',
  'mailer/submission.html.erb'
    ]
  s.homepage    = ''
  s.license     = 'MIT'
end