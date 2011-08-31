require 'rubygems'; require 'bundler'; Bundler.require; require 'erb'; require 'open-uri'

Samurai.options = YAML.load(open('https://raw.github.com/FeeFighters/samurai-sinatra-demo/master/samurai.yml').read).symbolize_keys
layout { open('https://raw.github.com/FeeFighters/samurai-sinatra-demo/master/views/layout.erb').read }

get '/' do
  @payment_method = OpenStruct.new :first_name=>'Joe', :last_name=>'FeeFighter', :card_number=>'4111111111111111', :cvv=>'123'
  erb Samurai::Rails::Views.payment_method_form_html, :locals=>{ :sandbox=>true, :redirect_url=>'/create-transaction' }
end

post '/create-transaction' do
  @transaction = Samurai::Processor.the_processor.purchase params[:payment_method_token], 111.11, :descriptor=>'Katana Sword'
  erb Samurai::Rails::Views.transaction_html
end