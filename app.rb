require "active_record"
require "base64"
require "dotenv"
require "json"
require "sinatra/base"

require "braintree"

Dotenv.load

Braintree::Configuration.environment = ENV["BT_ENVIRONMENT"]
Braintree::Configuration.merchant_id = ENV["BT_MERCHANT_ID"]
Braintree::Configuration.public_key  = ENV["BT_PUBLIC_KEY"]
Braintree::Configuration.private_key = ENV["BT_PRIVATE_KEY"]

class MyApp < Sinatra::Base
  get "/" do
    erb :index
  end

  get "/dropin-v2" do
    @token = Braintree::ClientToken.generate
    erb :dropin_v2
  end

  get "/dropin-v3" do
    @token = Braintree::ClientToken.generate
    erb :dropin_v3
  end

  get "/hf-v2" do
    @token = Braintree::ClientToken.generate
    erb :hf_v2
  end

  get "/hf-v3" do
    @token = Braintree::ClientToken.generate
    # p JSON.parse(Base64.decode64(@token), symbolize_names: true)
    erb :hf_v3
  end

  get "/token" do
    @token = Braintree::ClientToken.generate
    erb :token, :format => :json
  end

  post "/pm-create" do
    p "MADE IT TO POST PM CREATE ROUTE"
    p params.inspect

    nonce = params[:payment_method_nonce]
    p "nonce is assigned to #{nonce}"

    if params[:device_data]
      device_data = params[:device_data]
    else
      device_data = ""
    end

    @result = Braintree::PaymentMethod.create(
      :customer_id => "arenatest",
      :payment_method_nonce => nonce,
      :billing_address => {
        :country_code_alpha2 => "US",
        :postal_code => "99999"
      },
      :options => {
        :fail_on_duplicate_payment_method => false,
        :verify_card => true
      },
      :device_data => device_data
    )

    if @result.success?
      erb :pm_result
    else
      puts "ERROR: #{@result.inspect}"
      redirect back
    end
  end

  post "/transactions" do
    puts "MADE IT TO POST TRANSACTION ROUTE with NONCE:"
    puts params.inspect
    nonce = params[:payment_method_nonce]

    @result_transaction = Braintree::Transaction.sale(
      :amount               => "10.00",
      :payment_method_nonce => nonce,
      :options => {
        :submit_for_settlement => true
      }
    )

    if @result_transaction.success?
      erb :transaction_result
    else
      puts "ERROR: #{@result_transaction.inspect}"
      redirect back
    end
  end

  post "/webhooks" do
    p "HERE IS THE WEBHOOK REQEUST FROM BT"
    p JSON.pretty_generate(request.env)

    p "HERE IS THE RAW bt_signature"
    p request.params["bt_signature"]
    p "\n\nHERE IS THE RAW bt_payload"
    p request.params["bt_payload"]

    @webhook_notification = Braintree::WebhookNotification.parse(
      request.params["bt_signature"],
      request.params["bt_payload"]
    )

    p "HERE IS THE PARSED WEBHOOK"
    puts @webhook_notification.inspect

    case @webhook_notification.kind
    when Braintree::WebhookNotification::Kind::SubMerchantAccountApproved
      puts @webhook_notification.merchant_account.id
    when Braintree::WebhookNotification::Kind::SubscriptionWentActive
      puts @webhook_notification.subscription.transactions
    end

#    webhook_log = <<-LOG
#========== Webhook Received ==========

#Kind: #{@webhook_notification.kind}

#Contents: #{@webhook_notification.inspect}
#    LOG

#    File.open("../log/webhooks.log", "a+") do |f|
#      f.write webhook_log
#    end

    return 200
  end
end
