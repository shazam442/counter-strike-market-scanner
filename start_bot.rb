require 'json'
require 'httparty'
require 'dotenv/load'
require 'byebug'
require 'colorize'
require 'logger'
require 'base64'

require_relative './src/main'
require_relative './src/config'

config = getConfig

mainloop(config)

# expect item_list to contain at least one item of type String
# expect env variables to not be empty Strings