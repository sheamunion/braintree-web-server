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
    @webhook_notification = Braintree::WebhookNotification.parse(
      request.params["bt_signature"],
      request.params["bt_payload"]
    )
    puts @webhook_notification.inspect

    erb :webhook, :locals => {:webhook_notification => @webhook_notification}
  end
end