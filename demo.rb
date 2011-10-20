require 'rubygems'
require 'bundler'
Bundler.require
require 'open-uri'

Samurai.options = YAML.load(open( './samurai.yml').read).symbolize_keys

get '/' do; haml ''; end

post '/create-transaction' do
  @transaction = Samurai::Processor.the_processor.purchase params[:payment_method_token],
                                                           111.11,
                                                           :descriptor => 'Katana Sword'
  @transaction.to_json
end
