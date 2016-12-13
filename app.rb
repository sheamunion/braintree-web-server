require 'braintree'
require 'sinatra'
require 'dotenv'

Dotenv.load

Braintree::Configuration.environment = ENV['BT_ENVIRONMENT']
Braintree::Configuration.merchant_id = ENV['BT_MERCHANT_ID']
Braintree::Configuration.public_key  = ENV['BT_PUBLIC_KEY']
Braintree::Configuration.private_key = ENV['BT_PRIVATE_KEY']


get '/' do
  erb :index
end

get '/token' do
  @token = Braintree::ClientToken.generate
  response.body = {"client_token": "#{@token}"}
  puts(response.inspect)
  erb :token
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