# Salesforce Referral Integration

## Installation

Requires that the mail connector is configured.

Requires the following parameters to be configured as environmental variables. Speak to your Salesforce admin to be provided this values. Do not store the actual parameters in the code. Refer to them via the ENV.

```
OAUTH_CLIENT_ID
OAUTH_CLIENT_SECRET
SF_HOST
SF_USER
SF_PASS
SERVICE_IDENTIFIER
```

Copy the views from lib/salesforce_referral_mailer to app/vews

Switch the processing of user data to SalesforceReferrals.new(params)

## Website referral form

For the referrer

```
client_name
client_email
parent_id (the salesforce id)
```

For the referral

```
referral_first_name
referral_last_name
referral_phone
referral_email
referral_is_entrepreneur (as true / false)
referral_company
referral_kp_title
description
```

The process will transform them to the format / parameters expected by the webservice
