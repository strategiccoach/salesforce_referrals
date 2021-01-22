Gem::Specification.new do |s|
  s.name        = 'salesforce_referrals'
  s.version     = '0.0.1'
  s.date        = '2021-01-20'
  s.summary     = "Salesforce Referrals Integration"
  s.description = "Push incoming referrals to a Salesforce API endpoint for automated integration"
  s.authors     = ["Paul Devisser"]
  s.email       = 'paul.devisser@strategiccoach.com'
  s.files       = `git ls-files -z`.split("\x0").select{|f| f.start_with?('app',  'lib', 'saleseforce_referrals.gemspec', 'LICENSE', 'README') }
  s.homepage    = ''
  s.license     = 'MIT'
end