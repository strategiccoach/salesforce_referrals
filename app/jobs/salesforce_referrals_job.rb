class SalesforceReferralsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # all good status code. Start here
    status_code = 200
    # setup data
    # POST data to salesforce endpoint
    # send off emails

    # 
  end
end