require 'json'
require 'httparty'
require 'dotenv/load'
require 'byebug'
require 'colorize'
require 'logger'
require 'base64'
require 'nokogiri'

require_relative './src/main'

default_config = {
    targets: [],
    target_price: 0,
    request_interval_seconds: 60,
    env: {
        "skinbaron_api_key": ENV['SKINBARON_API_KEY'],
        "skinport_client_id": ENV["SKINPORT_CLIENT_ID"],
        "skinport_client_secret": ENV["SKINPORT_CLIENT_SECRET"]
    }
}

file = File.read("config.json")
file_config = JSON.parse(file).transform_keys(&:to_sym)
file_config[:targets].transform_keys!(&:to_sym)

config = default_config.merge file_config

mainloop(config)