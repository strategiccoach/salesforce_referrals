class SalesforceReferrals ; VERSION= '0.0.1'

  VARS = { referrer_first_name: '', referrer_last_name: '', referrer_email: '', salesforce_id: '',
    referral_first_name: '', referral_last_name: '', 
    referral_email: '',  referral_phone:  '',
    referral_kp_title: '', referral_is_entrepreneur: false
  }
  EMAIL_REGEX = /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i

  attr_reader :form_errors, :form_vars, :status_code

  def initialize(args)
    @status_code = 200
    @form_vars = VARS.merge(args.delete_if { |_,v| v.nil? || v == '' })
    @form_errors = []
    # validate information. 
    if !EMAIL_REGEX.match(@form_vars[:referrer_email])
      @status_code = 600
      @form_errors << "Please ensure your email is correct."
    end
    if !EMAIL_REGEX.match(@form_vars[:referral_email])
      @status_code = 600
      @form_errors << "Please ensure your referral's email is correct."
    end
  end

  def perform
    # catch if email validation somehow gets ignored
    if not @status_code.eql?(200)
      return
    end
    auth_params = logging_in
    data = {
      source: ENV['SERVICE_IDENTIFIER'],
      referrer_id: @form_vars['salesforce_id'],
      referrer_first_name: @form_vars['referrer_first_name'],
      referrer_last_name: @form_vars['referrer_last_name'],
      referrer_email: @form_vars['referrer_email'],
      form_data: {
        referral_first_name: @form_vars['referral_first_name'],
        referral_last_name: @form_vars['referral_last_name'],
        referral_phone: @form_vars['referral_phone'],
        referral_email: @form_vars['referral_email'].to_s.downcase,
        referral_is_entrepreneur: @form_vars['referral_is_entrepreneur'],
        referral_kp_title: @form_vars['referral_kp_title'],
      }
    }

    # Alpha may change with refreshes. use instance url
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

    if results['status'].blank?
      @form_errors << "FATAL Exception"
      @form_errors << "There was an unrecoverable error."
      @form_errors << results['description']
      @form_errors << results['exception']
    elsif results['status'].present? && results['status'].eql?(100)
      @status_code = 200
    else
      case results['status']
      when '200'
        @form_errors << "Results returned from Salesforce: #{results['status']}"
        @form_errors << "<strong>Failed</strong>"
        @form_errors << results['description']
      when "325"
        @form_errors << "We found a dupicate entry in our database. We cannot add them at this time. Please inform your program advisor with the correct information."
      else
        # error!
        @form_errors << "<strong>Failed</strong>"
        @form_errors << results['description'] if results['description']
        @form_errors << results['exception'] if results['exception']
        
      end
    end
    if @status_code.eql?(200)
      SendReferralsMailer.submission(@form_vars).deliver_now
    else
      SalesForceReferralErrorMailer.errors(@form_errors, @form_vars).deliver_now
    end
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