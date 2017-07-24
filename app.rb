require 'braintree'
require 'sinatra/base'
require 'dotenv'
require 'active_record'

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

  get '/dropin-v3' do
    @token = Braintree::ClientToken.generate
    puts(response.inspect)
    erb :dropin_v3
  end

  get '/token' do
    token = Braintree::ClientToken.generate
    response.body = token
    puts(response.inspect)
    erb :token, :format => :json
  end

  post '/transaction' do
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
    puts Braintree::WebhookNotification.parse(
      request.params["bt_signature"],
      request.params["bt_payload"]
    )
    # @webhook_notification = Braintree::WebhookNotification.parse(
    #   request.params["bt_signature"],
    #   request.params["bt_payload"]
    # )

    # # Example values for webhook notification properties
    # puts "Webhook kind: "
    # puts @webhook_notification.kind # "subscription_went_past_due"
    # puts "Webhook timestamp: "
    # puts @webhook_notification.timestamp # "Sun Jan 1 00:00:00 UTC 2012"
    # puts "Webhook merchant account: "
    # puts @webhook_notification.merchant_account

    erb :webhook
  end
end