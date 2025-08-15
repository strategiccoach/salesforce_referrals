# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby gem for Salesforce referral integration that processes incoming referrals and pushes them to a Salesforce API endpoint. The gem handles form validation, OAuth authentication, API communication, and email notifications for both successful submissions and errors.

## Architecture

### Core Components

- **SalesforceReferrals** (`lib/salesforce_referrals/salesforce_referrals.rb`): Main class that handles form validation, OAuth authentication with Salesforce, and API communication
- **SalesforceReferralsMailer** (`lib/salesforce_referrals/salesforce_referrals_mailer.rb`): ActionMailer class for sending notification emails
- **Email Templates** (`lib/salesforce_referrals_mailer/`): HTML templates for error notifications and submission confirmations

### Key Workflows

1. **Form Processing**: Initialize with form parameters and optional captcha validation
2. **Validation**: Check required fields (names, email formats, entrepreneur status)
3. **OAuth Authentication**: Login to Salesforce using username/password OAuth flow
4. **API Submission**: POST referral data to `/services/apexrest/NewContact` endpoint
5. **Error Handling**: Send detailed error reports via email when submission fails
6. **Success Notification**: Optional email confirmation for successful submissions

### Environment Variables

Required configuration (set via ENV):
- `OAUTH_CLIENT_ID` - Salesforce OAuth client ID
- `OAUTH_CLIENT_SECRET` - Salesforce OAuth client secret  
- `SF_HOST` - Salesforce host URL
- `SF_USER` - Salesforce username
- `SF_PASS` - Salesforce password
- `SERVICE_IDENTIFIER` - Source identifier for referrals

Optional configuration:
- `ONLY_REQUIRE_ONE` - Set to 1 to require either email OR phone (not both)
- `SEND_REFERRAL_EMAIL` - Set to 1 to send confirmation emails
- `DEBUG` - Set to 1 to enable debug logging and send debug emails
- `GCAPTCHA_SECRET` / `GCAPTCHA_URL` - For Google reCAPTCHA validation

## Development Commands

This is a Ruby gem project. Standard gem development workflow applies:

```bash
# Build the gem
gem build salesforce_referrals.gemspec

# Install locally for testing
gem install salesforce_referrals-0.1.5.0.gem

# Test integration (requires Rails environment with proper ENV vars)
# No automated test suite - testing done via Rails integration
```

## Integration Usage

When integrating into a Rails application:

1. Copy email templates from `lib/salesforce_referral_mailer` to `app/views`
2. Replace form processing with `SalesforceReferrals.new(params)`
3. Call `perform()` method to process the referral

## Error Codes

The Salesforce API returns specific error codes (300-series) that map to user-friendly error messages. Key error codes include:
- 310: Missing first name
- 311: Missing last name  
- 312: Missing email
- 313: Missing email or phone
- 320-328: Various processing errors
- 350: Unhandled exception

## Form Data Structure

Expected form parameters:
- **Referrer**: `client_name`, `client_email`, `parent_id`
- **Referral**: `referral_first_name`, `referral_last_name`, `referral_phone`, `referral_email`, `referral_is_entrepreneur`, `referral_company`, `referral_kp_title`, `description`, `referral_relationship`, `referral_country`