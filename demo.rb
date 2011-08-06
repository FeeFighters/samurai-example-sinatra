require 'rubygems'
require 'bundler'
Bundler.require
require 'erb'

Samurai.options = YAML.load_file('samurai.yml').symbolize_keys

get '/' do
  erb Samurai::PaymentMethod.form_html, :locals=>{ :redirect_url=>url('/new-transaction'), :sandbox => true }
end

get '/new-transaction' do
  erb Samurai::Transaction.form_html, :locals=>{
    :payment_method => Samurai::PaymentMethod.find(params[:payment_method_token]),
    :processor_token => Samurai::Processor.the_processor.id,
    :post_url => '/create-transaction',
  }
end

post '/create-transaction' do
  processor = Samurai::Processor.the_processor
  purchase = processor.purchase params[:payment_method_token], params[:amount], params[:transaction]
  erb Samurai::Transaction.show_html, :locals=>{ :transaction=>purchase }
end