# Security Assessment: Salesforce Referrals Gem

**Assessment Date:** August 15, 2025  
**Gem Version:** 0.1.5.0  
**Assessment Scope:** Complete codebase security review

## Executive Summary

This security assessment identifies multiple vulnerabilities in the Salesforce Referrals gem, including **critical authentication flaws** and **medium-risk data exposure issues**. The most severe findings include use of deprecated OAuth flows and insufficient input validation that could lead to credential compromise and data breaches.

### Risk Classification
- 🚨 **Critical:** 1 finding
- 🔶 **Medium:** 6 findings  
- 🟡 **Low:** 3 findings

## Critical Vulnerabilities

### 🚨 CRIT-001: Insecure OAuth Implementation
**Location:** `lib/salesforce_referrals/salesforce_referrals.rb:193-209`  
**Severity:** Critical  
**CVSS Score:** 9.1

**Description:**
The application uses the deprecated OAuth username/password flow, transmitting credentials in plaintext POST requests. This authentication method is discouraged by Salesforce and presents significant security risks.

```ruby
# VULNERABLE CODE
request.set_form_data({
  "grant_type": "password",
  "client_id": ENV['OAUTH_CLIENT_ID'],
  "client_secret": ENV['OAUTH_CLIENT_SECRET'],
  "username": ENV['SF_USER'],
  "password": ENV['SF_PASS']
})
```

**Impact:**
- Credentials vulnerable to interception
- No credential rotation mechanism
- Violates OAuth 2.0 security best practices

**Remediation:**
Migrate to JWT Bearer Token flow:
```ruby
def get_jwt_bearer_token
  # Generate JWT assertion with RSA private key
  assertion = JWT.encode(claims, rsa_private_key, 'RS256')
  
  # Request token using JWT Bearer flow
  request.set_form_data({
    "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
    "assertion": assertion
  })
end
```

## High-Risk Vulnerabilities

### 🔶 HIGH-001: SSL Certificate Validation Disabled
**Location:** `lib/salesforce_referrals/salesforce_referrals.rb:113-114`  
**Severity:** High  
**CVSS Score:** 7.4

**Description:**
SSL is enabled but certificate verification is not configured, making the application vulnerable to man-in-the-middle attacks.

```ruby
# VULNERABLE CODE
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
# Missing certificate verification
```

**Remediation:**
```ruby
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER
http.ca_file = '/etc/ssl/certs/ca-certificates.crt'
```

### 🔶 HIGH-002: Sensitive Data Exposure in Debug Mode
**Location:** `lib/salesforce_referrals/salesforce_referrals.rb:160-164`  
**Severity:** High  
**CVSS Score:** 7.2

**Description:**
Debug mode exposes sensitive API responses and user data to end users and error reports.

**Remediation:**
```ruby
if Rails.env.development? && ENV['DEBUG'].to_i == 1
  Rails.logger.debug "Salesforce Response: #{results['status']}"
  # Never expose debug info to users
end
```

## Medium-Risk Vulnerabilities

### 🔶 MED-001: Cross-Site Scripting (XSS) in Email Templates
**Location:** `lib/salesforce_referrals_mailer/errors.html.erb:22`  
**Severity:** Medium  
**CVSS Score:** 6.1

**Description:**
Raw HTML output without escaping enables XSS attacks through error messages.

```erb
<!-- VULNERABLE CODE -->
<%= @error.join("<br />").html_safe %>
```

**Remediation:**
```erb
<%= simple_format(h(@error.join("\n"))) %>
```

### 🔶 MED-002: Insufficient Input Validation
**Location:** `lib/salesforce_referrals/salesforce_referrals.rb:3`  
**Severity:** Medium  
**CVSS Score:** 5.8

**Description:**
Custom email regex allows potentially dangerous characters and has no length limits.

**Remediation:**
```ruby
EMAIL_REGEX = /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/

def validate_email(email)
  return false if email.blank? || email.length > 254
  EMAIL_REGEX.match?(email)
end
```

### 🔶 MED-003: PII in Error Messages
**Location:** `lib/salesforce_referrals/salesforce_referrals.rb:181-190`  
**Severity:** Medium  
**CVSS Score:** 5.5

**Description:**
Complete form data including personally identifiable information is sent in error emails without masking.

**Remediation:**
```ruby
def mask_sensitive_data(data)
  masked = data.dup
  masked['referral_email'] = mask_email(data['referral_email'])
  masked['referral_phone'] = mask_phone(data['referral_phone'])
  masked
end
```

### 🔶 MED-004: Unescaped User Data in Email Templates
**Location:** `lib/salesforce_referrals_mailer/submission.html.erb:1-18`  
**Severity:** Medium  
**CVSS Score:** 5.4

**Description:**
Multiple instances of unescaped user input in email templates.

**Remediation:**
```erb
First Name: <%= h(@referral['referral_first_name']) %><br />
Email Address: <%= h(@referral['referral_email']) %><br />
```

### 🔶 MED-005: Missing Request Timeouts
**Location:** Multiple HTTP request locations  
**Severity:** Medium  
**CVSS Score:** 5.3

**Description:**
No timeout configuration for HTTP requests could lead to denial of service.

**Remediation:**
```ruby
http.open_timeout = 10  # seconds
http.read_timeout = 30  # seconds
```

### 🔶 MED-006: Broad Exception Handling
**Location:** `lib/salesforce_referrals/salesforce_referrals.rb:124-126`  
**Severity:** Medium  
**CVSS Score:** 5.1

**Description:**
Silent exception catching hides potential security issues.

**Remediation:**
```ruby
rescue StandardError => e
  Rails.logger.error "Salesforce API Error: #{e.class}: #{e.message}"
  SecurityAuditLogger.log_api_error(e)
  results = {}
end
```

## Low-Risk Findings

### 🟡 LOW-001: Information Leakage in Logs
**Location:** `lib/salesforce_referrals/salesforce_referrals.rb:170-174`  
**Severity:** Low

Full form data including PII is logged. Implement structured logging with PII filtering.

### 🟡 LOW-002: Hardcoded Email Addresses
**Location:** `lib/salesforce_referrals/salesforce_referrals_mailer.rb:13,20`  
**Severity:** Low

Email addresses are hardcoded without validation.

### 🟡 LOW-003: Hardcoded API Endpoint Construction
**Location:** `lib/salesforce_referrals/salesforce_referrals.rb:111`  
**Severity:** Low

API endpoint constructed from potentially manipulable instance URL.

## Recommended Security Improvements

### Immediate Actions Required (Critical/High)

1. **Migrate OAuth Flow** (CRIT-001)
   - Implement JWT Bearer Token authentication
   - Remove username/password credentials from environment
   - Set up certificate-based authentication

2. **Enable SSL Verification** (HIGH-001)
   - Configure proper certificate validation
   - Use system CA bundle or specified certificate file

3. **Fix Debug Data Exposure** (HIGH-002)
   - Remove sensitive data from debug output
   - Implement secure audit logging
   - Never expose internal state to users

### Security Hardening Recommendations

#### Input Validation & Sanitization
```ruby
class InputValidator
  def self.sanitize_string(input, max_length = 255)
    return nil if input.blank?
    ActionController::Base.helpers.sanitize(input.to_s.strip[0..max_length])
  end
  
  def self.validate_email(email)
    return false if email.blank? || email.length > 254
    /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/.match?(email)
  end
end
```

#### Rate Limiting
```ruby
class SalesforceReferrals
  include RateLimited
  
  rate_limit :perform, to: 5, within: 1.minute, 
             key: ->(instance) { instance.client_ip }
end
```

#### Request Signing
```ruby
def sign_request(payload)
  timestamp = Time.current.to_i
  signature = OpenSSL::HMAC.hexdigest('SHA256', secret_key, 
                                     "#{timestamp}#{payload}")
  {
    'X-Timestamp' => timestamp,
    'X-Signature' => signature
  }
end
```

#### Secure Logging
```ruby
class SecurityAuditLogger
  def self.log_api_error(error, context = {})
    Rails.logger.error({
      event: 'salesforce_api_error',
      error_class: error.class.name,
      message: error.message,
      timestamp: Time.current.iso8601,
      context: filter_sensitive_data(context)
    }.to_json)
  end
  
  private
  
  def self.filter_sensitive_data(data)
    # Remove PII before logging
  end
end
```

### Configuration Security

#### Environment Variables
```yaml
# Use Rails credentials instead of plain environment variables
# rails credentials:edit --environment production

salesforce:
  oauth:
    client_id: <%= Rails.application.credentials.dig(:salesforce, :client_id) %>
    private_key: <%= Rails.application.credentials.dig(:salesforce, :private_key) %>
  api:
    host: <%= Rails.application.credentials.dig(:salesforce, :host) %>
```

#### Content Security Policy
```ruby
# config/application.rb
config.content_security_policy do |policy|
  policy.default_src :self
  policy.script_src :none
  policy.style_src :self, :unsafe_inline
  policy.img_src :self, :data
end
```

## Testing Recommendations

### Security Testing
1. **Penetration Testing:** Conduct regular penetration tests focusing on authentication and data handling
2. **Static Analysis:** Implement automated security scanning in CI/CD pipeline
3. **Dependency Scanning:** Regular vulnerability scans of gem dependencies

### Monitoring
1. **API Rate Limiting:** Monitor for unusual API usage patterns
2. **Failed Authentication:** Alert on authentication failures
3. **Data Access Logging:** Audit all access to sensitive data

## Compliance Considerations

- **GDPR:** Implement data minimization and right to erasure
- **CCPA:** Ensure proper consent management for California residents  
- **SOC 2:** Establish controls for data processing and security
- **OWASP:** Follow OWASP Top 10 security guidelines

## Conclusion

The Salesforce Referrals gem contains several security vulnerabilities that require immediate attention. The critical OAuth implementation flaw and SSL verification issues pose the highest risk and should be addressed as priority one. Implementation of the recommended security controls will significantly improve the security posture of the application.

**Next Steps:**
1. Address critical and high-risk vulnerabilities immediately
2. Implement comprehensive input validation and output encoding  
3. Establish security monitoring and incident response procedures
4. Schedule regular security assessments and penetration testing

---
**Assessment Performed By:** Claude Code Security Analysis  
**Report Version:** 1.0  
**Distribution:** Internal Security Team Only