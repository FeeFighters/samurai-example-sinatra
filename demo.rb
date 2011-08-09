require 'rubygems'; require 'bundler'; Bundler.require; require 'erb'; require 'open-uri'

Samurai.options = YAML.load_file('samurai.yml').symbolize_keys

Samurai.options = YAML.load(open('https://raw.github.com/FeeFighters/samurai-sinatra-demo/master/samurai.yml').read).symbolize_keys
layout { open('https://raw.github.com/FeeFighters/samurai-sinatra-demo/master/views/layout.erb').read }

get '/' do
  payment_method = OpenStruct.new :first_name=>'Joe', :last_name=>'FeeFighter', :card_number=>'4111111111111111', :cvv=>'123'
  erb Samurai::PaymentMethod.form_html, :locals=>{ :redirect_url=>url('/new-transaction'), :sandbox => true, :payment_method=>payment_method }
end

get '/new-transaction' do
  erb Samurai::Transaction.form_html, :locals=>{
    :payment_method => Samurai::PaymentMethod.find(params[:payment_method_token]),
    :processor_token => Samurai::Processor.the_processor.id,
    :post_url => '/create-transaction',
    :transaction => OpenStruct.new(:currency_code=>'US'),
  }
end

post '/create-transaction' do
  processor = Samurai::Processor.the_processor
  purchase = processor.purchase params[:payment_method_token], params[:amount], params[:transaction]
  erb Samurai::Transaction.show_html, :locals=>{ :transaction=>purchase }
end