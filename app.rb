require 'braintree'
require 'sinatra/base'
require 'dotenv'
require 'active_record'
require 'base64'
require 'json'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'postgres://localhost/mydb')

Dotenv.load

Braintree::Configuration.environment = ENV['BT_ENVIRONMENT']
Braintree::Configuration.merchant_id = ENV['BT_MERCHANT_ID']
Braintree::Configuration.public_key  = ENV['BT_PUBLIC_KEY']
Braintree::Configuration.private_key = ENV['BT_PRIVATE_KEY']

class MyApp < Sinatra::Base
  get '/' do
    erb :index
  end

  get '/dropin-v2' do
    @token = Braintree::ClientToken.generate
    puts(response.inspect)
    erb :dropin_v2
  end

  get '/dropin-v3' do
    @token = Braintree::ClientToken.generate
    puts(response.inspect)
    erb :dropin_v3
  end

  get '/hf-v3' do
    @token = Braintree::ClientToken.generate(:customer_id => "apisupport")
    p JSON.parse(Base64.decode64(@token), symbolize_names: true)
    erb :hf_v3
  end

  get '/token' do
    token = Braintree::ClientToken.generate
    response.body = token
    puts(response.inspect)
    erb :token, :format => :json
  end

  post '/pm-create' do
    p "MADE IT TO POST PM CREATE ROUTE"
    p params.inspect
    nonce = params[:nonce]
    p "nonce is assigned to #{nonce}"

    @result = Braintree::PaymentMethod.create(
      # :cardholder_name => "bippity bop",
      :customer_id => "apisupport",
      :payment_method_nonce => nonce,
      :billing_address => {
        # :country_name => "United States of America"
        :country_code_alpha2 => "US",
        :postal_code => "99999"
      },
      :options => {
        :fail_on_duplicate_payment_method => false,
        :verify_card => true
      },
      :device_data => ""
    )
    p @result.inspect

    if @result.success?
      erb :result
    else
      erb :hf_v3
    end
  end

  post '/transaction' do
    puts "MADE IT TO POST TRANSACTION ROUTE"
    puts params.inspect
    nonce = params[:payment_method_nonce]

    result_transaction = Braintree::Transaction.sale(
        :amount               => "23",
        :payment_method_nonce => nonce,
        :options => {
          :submit_for_settlement => true
        }
      )
    erb :result
  end

  post "/webhooks" do
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

    erb :webhook, :locals => {:webhook_notification => @webhook_notification}
  end
end