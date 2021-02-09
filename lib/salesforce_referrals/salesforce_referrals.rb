class SalesforceReferrals

  EMAIL_REGEX = /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i

  attr_reader :form_errors, :form_vars, :status_code, :mailer

  def initialize(form_vars, captcha = nil)
    @status_code = 200
    @form_vars = form_vars
    @form_errors = []
    # validate information. 
    if @form_vars['parent_id'].blank? && !EMAIL_REGEX.match(@form_vars['client_email'])
      @status_code = 600
      @form_errors << "Please ensure your email is correct."
    end
    if @form_vars['referral_email'].blank? && @form_vars['referral_phone'].blank?
      @status_code = 600
      @form_errors << "Please provide your referral's email or phone number."
    end
    if @form_vars['referral_first_name'].blank? || @form_vars['referral_last_name'].blank?
      @status_code = 600
      @form_errors << "Please provide your referral's full name."
    end
    if !@form_vars['referral_email'].blank? && !EMAIL_REGEX.match(@form_vars['referral_email'])
      @status_code = 600
      @form_errors << "Please ensure your referral's email is correct."
    end
    if not ENV['SERVICE_IDENTIFIER'].eql?('referral_client')
      if @form_vars['referral_is_entrepreneur'].blank?
        @status_code = 600
        @form_errors << "Please let us know if your referral is an entrepreneur."
      end
      perform_google_check(captcha)
    end
  end

  def perform_google_check(captcha)
    # https://www.google.com/recaptcha/api/siteverify
    data = [
      [ "secret", ENV['GCAPTCHA_SECRET']] ,
      [ "response", captcha ]
    ]
    uri = URI.parse(ENV['GCAPTCHA_URL'])
    form = URI.encode_www_form(data)
    headers = { content_type: "application/x-www-form-urlencoded" }
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.request_post(uri.path, form, headers)
    # request = Net::HTTP::Post.new(uri.request_uri)
    # response = http.request(request)
    results = JSON.parse(response.body) rescue {}

    if ENV['DEBUG'].to_i == 1
      Rails.logger.info ">> CAPTCHA: #{results}"
    end
    if results['success'] == false
      @status_code = 600
      @form_errors << "Request timed out. Please try again." if @form_errors.blank?
    end
  end

  def perform(status = 1)
    # catch if email validation somehow gets ignored
    if not @status_code.eql?(200)
      return
    end
    auth_params = logging_in

    if not auth_params['instance_url'].present?
      @form_errors << "Login Problem. Not able to connect to the Salesforce Server. Aborting."
      @status_code = 600
      send_error_report
      return false
    end

    is_ent = @form_vars['referral_is_entrepreneur'].eql?(true) ? "Yes" : "No"
    @form_errors = []

    data = {
      source: ENV['SERVICE_IDENTIFIER'],
      parent_id: @form_vars['parent_id'],
      form_data: {
        # referrer
        client_name: @form_vars['client_name'],
        client_email: @form_vars['client_email'].to_s.downcase,
        first_name: @form_vars['referral_first_name'],
        last_name: @form_vars['referral_last_name'],
        phone: @form_vars['referral_phone'],
        email: @form_vars['referral_email'].to_s.downcase,
        company: @form_vars['referral_company'],
        relationship: @form_vars['referral_relationship'],
        entrepreneur: is_ent,
        kp: @form_vars['referral_kp_title'],
        description: @form_vars['description']
      }
    }
    # Alpha may change with refreshes. use instance url
    begin
      api_url = "#{auth_params['instance_url']}/services/apexrest/NewContact"
      uri = URI.parse(api_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
    
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Authorization'] = "Bearer #{auth_params["access_token"]}"
      # use json
      request['Content-Type'] = "application/json"
      request.body = data.to_json
    
      response = http.request(request)
      results = JSON.parse(response.body) rescue {}
    rescue
    end

    if results['status'].blank?
      @status_code = 500
      @form_errors << "FATAL Exception"
      @form_errors << "There was an unrecoverable error."
      @form_errors << results['description']
      @form_errors << results['exception']
    elsif results['status'].present? && results['status'].eql?('100')
      @status_code = 200
    else
      @status_code = 300
      case results['status']
      # when '200'
      #   @form_errors << "Results returned from Salesforce: #{results['status']}"
      #   @form_errors << "<strong>Failed: #{results['status']}</strong>"
      #   @form_errors << results['description']
      when '310'
        @form_errors << 'Please provide a First Name'
      when '311'
        @form_errors << 'Please provide a Last Name'
      when '312'
        @form_errors << 'Please provide an Email address'
      when '313'
        @form_errors << 'Please provide either Email or Phone'
      else
        @status_code = 500
        # error!
        @form_errors << "<strong>Failed: #{results['status']}</strong>"
        @form_errors << results['description'] if results['description']
        @form_errors << results['exception'] if results['exception']
      end
    end

    if ENV['DEBUG'].to_i == 1
      @form_errors.unshift "Salesforce Returned: #{results['status']}"
      @form_errors.unshift "<strong>DEBUGGING ENABLED</strong>"
      send_error_report(data)
    end

    if @status_code.eql?(200) && ENV['SEND_REFERRAL_EMAIL'].to_i.eql?(1)
      SalesforceReferralsMailer.submission(@form_vars).deliver_now
    elsif not @status_code.eql?(200)
      send_error_report(data)
    end
  end

  def send_error_report(data = {})
    SalesforceReferralsMailer.errors(@form_errors, @form_vars, data).deliver_now
  end

  # login to salesforce using OAuth2
  def logging_in
    auth_url = ENV['SF_HOST'] + "/services/oauth2/token"
    uri = URI.parse(auth_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data({
      "grant_type": "password",
      "client_id": ENV['OAUTH_CLIENT_ID'],
      "client_secret": ENV['OAUTH_CLIENT_SECRET'],
      "username": ENV['SF_USER'],
      "password": ENV['SF_PASS']
    })

    response = http.request(request)
    JSON.parse(response.body)
  end

end

=begin
  300 => 'Source is not provided'
301 => 'Source provided is not valid'
302 => 'Please provide your Id or Email'
303 => 'Your Contact Id is not valid'
305 => 'The Contact Id you have provided is not valid'
310 => 'Please provide a First Name'
311 => 'Please provide a Last Name'
313 => 'Please provide either Email or Phone'

I also adjusted the error text on some to be a little more front-stage friendly, if you choose to expose them to the end-user. This is the full set of error codes/descriptions. There might be a couple new ones to account for - I don't know if you just look for anything that starts with "3" or if you look for the specific codes.
'300' => 'Source is not provided'
'301' => 'Source provided is not valid'
'302' => 'Please provide your Id or Email'
'303' => 'Your Contact Id is not valid'
'304' => 'We could not find a record of you in our system'
'305' => 'The Contact Id you have provided is not valid'
'306' => 'Your ACL record does not exist'
'320' => 'Error occurred while updating contact/lead'
'321' => 'Error occurred while inserting contact/lead'
'322' => 'Error occurred while querying for the contact'
'323' => 'Error occurred while querying for the lead'
'324' => 'Error occurred while inserting the relationship'
'325' => 'Existing record found as a lead, not contact'
'326' => 'Error occurred while inserting the referral'
'327' => 'Error occurred while inserting the task'
'328' => 'Error occurred while inserting the ACL'
'350' => 'An unhandled exception has occurred'

=end