class SalesforceReferrals ; VERSION= '0.0.1'

  EMAIL_REGEX = /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i

  attr_reader :form_errors, :form_vars, :status_code, :mailer

  def initialize(form_vars)
    @status_code = 200
    @form_vars = form_vars
    @form_errors = []
    # validate information. 
    if @form_vars['parent_id'].blank? && !EMAIL_REGEX.match(@form_vars['client_email'])
      @status_code = 600
      @form_errors << "Please ensure your email is correct."
    end
    if not @form_vars['referral_email'].present? && @form_vars['referral_phone'].present?
      @status_code = 600
      @form_errors << "Please provide your referral's email or phone number."
    end
    if @form_vars['referral_first_name'].blank? || @form_vars['referral_last_name'].blank?
      @status_code = 600
      @form_errors << "Please provide your referral's full name."
    end
    if @form_vars['referral_email'].present? && !EMAIL_REGEX.match(@form_vars['referral_email'])
      @status_code = 600
      @form_errors << "Please ensure your referral's email is correct."
    end
    if not ENV['SERVICE_IDENTIFIER'].eql?('referral_client')
      if @form_vars['referral_is_entrepreneur'].blank?
        @status_code = 600
        @form_errors << "Please let us know if your referral is an entrepreneur."
      end
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

    @form_errors = []

    if results['status'].blank?
      @form_errors << "FATAL Exception"
      @form_errors << "There was an unrecoverable error."
      @form_errors << results['description']
      @form_errors << results['exception']
    elsif results['status'].present? && results['status'].eql?('100')
      @status_code = 200
    else
      case results['status']
      when '200'
        @form_errors << "Results returned from Salesforce: #{results['status']}"
        @form_errors << "<strong>Failed: #{results['status']}</strong>"
        @form_errors << results['description']
      when "325"
        @form_errors << "We found a dupicate entry in our database. We cannot add them at this time. Please inform your program advisor with the correct information."
      else
        # error!
        @form_errors << "<strong>Failed: #{results['status']}</strong>"
        @form_errors << results['description'] if results['description']
        @form_errors << results['exception'] if results['exception']
        
      end
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