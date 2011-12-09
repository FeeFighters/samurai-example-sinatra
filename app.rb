require 'rubygems'
require 'open-uri'
require 'bundler'
Bundler.require

require 'sinatra/content_for'
require 'cgi'

Samurai.options = {
  :site              => 'https://api.samurai.feefighters.com/v1/',
  :merchant_key      => 'a1ebafb6da5238fb8a3ac9f6',
  :merchant_password => 'ae1aa640f6b735c4730fbb56',
  :processor_token   => '5a0e1ca1e5a11a2997bbf912'
}

include Samurai::Rails::Helpers

# =============================================================================

get '/' do
  erb :index
end

# Payment form for Samurai.js
# ------------------------------
#
# * displays a drop-in payment form from Samurai.js, no extra logic required
get '/samurai_js/payment_form' do
  erb :'samurai_js/payment_form'
end

# Purchase action for Samurai.js
# ------------------------------
#
# * payment_method_token is POST'd via AJAX
# * Responds with a JSON transaction object
#
post '/samurai_js/purchase', :provides => 'json' do
  @transaction = Samurai::Processor.the_processor.purchase(
    params[:payment_method_token],
    122.00,  # The price for the Samurai.js Katana Sword
    {
      :descriptor => 'Samurai.js Katana Sword',
      :customer_reference => Time.now.to_f,
      :billing_reference => Time.now.to_f
    }
  )

  @transaction.to_json
end

# =============================================================================

# Payment form for Transparent Redirect
# ------------------------------
#
# * Displays a payment form using the Samurai Rails helpers bundled in the gem
# * Payment form is initialized with PaymentMethod data, if a token is passed in the params.
#   This allows validation & processor-response error messages to be displayed.
#
get '/transparent_redirect/payment_form' do
  setup_for_transparent_redirect(params)
  erb :'transparent_redirect/payment_form'
end

# Purchase action for Transparent Redirect
# ------------------------------
#
# * This action is requested as the callback from the Samurai.js Transparent Redirect
# * It performs the purchase, and redirects the user to the purchase confirmation page
# * On error, it redirects back to the payment form to display validation/card errors
#
get '/transparent_redirect/purchase' do
  load_and_verify_payment_method(params)
  unless @payment_method
    redirect to('/transparent_redirect/payment_form?payment_method_token='+payment_method_params[:payment_method_token]) 
  end

  @transaction = Samurai::Processor.the_processor.purchase(
    @payment_method.token,
    122.00,  # The price for the Transparent Redirect Nunchucks
    {
      :descriptor => 'Transparent Redirect Nunchucks',
      :customer_reference => Time.now.to_f,
      :billing_reference => Time.now.to_f
    }
  )

  if @transaction.failed?
    redirect to('/transparent_redirect/payment_form?payment_method_token='+payment_method_params[:payment_method_token]) 
  end

  redirect to('/transparent_redirect/receipt')
end

# =============================================================================

# Payment form for Server-to-Server API
# -------------------------------------
#
# * Displays a payment form that POSTs to the purchase method below
# * The credit card data is provided directly to this rails server, where it is used to process a
#   transaction entirely on the backend.
# * A payment_method_token or reference_id can be provided in the params so that validation errors can be displayed.
#
get '/server_to_server/payment_form' do 
  unless params[:payment_method_token].nil?
    @payment_method = Samurai::PaymentMethod.find params[:payment_method_token]
  else
    @payment_method = Samurai::PaymentMethod.new :is_sensitive_data_valid => false
  end

  unless params[:reference_id].nil?
    @transaction = Samurai::Transaction.find params[:reference_id]
  end

  erb :'server_to_server/payment_form'
end

# Purchase action for Server-to-Server API
# ----------------------------------------
#
# * Payment Method details are POST'ed directly to the server, which performs a S2S API call
# * NOTE: This approach is typically not recommended, as it comes with a much greater PCI compliance burden
#   In general, it is a good idea to prevent the credit card details from ever touching your server.
#
post '/server_to_server/purchase' do
  @payment_method = Samurai::PaymentMethod.create params[:payment_method]
  if @payment_method.nil?
    redirect to('/server_to_server/payment_form')
  end

  @transaction = Samurai::Processor.the_processor.purchase(
    @payment_method.token,
    122.00,  # The price for the Server-to-Server Battle Axe + Shipping
    {
      :descriptor => 'Server-to-Server Battle Axe',
      :customer_reference => Time.now.to_f,
      :billing_reference => Time.now.to_f
    }
  )

  unless @transaction.success
    query = { :payment_method_token => @payment_method.token, 
              :reference_id => @transaction.reference_id 
            }.map { |k, v| "#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}" }.join('&')

    redirect to('/server_to_server/payment_form?'+query)
  end

  redirect to('/server_to_server/receipt')
end

# Purchase confirmation & receipt page
# ------------------------------------
get %r{/(samurai_js|transparent_redirect|server_to_server)/receipt} do |t|
  erb :"#{t}/receipt"
end


