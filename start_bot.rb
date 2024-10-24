require_relative './src/main.rb'

item_list = [
    "M249 | Humidor (Factory New)",
    "SG 553 | Desert Blossom (Factory New)",
    "USP-S | Purple DDPAT (Factory New)",
    "MP9 | Music Box (Factory New)"
]

request_interval_seconds = 60

SKINBARON_API_KEY = ENV['SKINBARON_API_KEY']
SKINPORT_CLIENT_ID = ENV["SKINPORT_CLIENT_ID"]
SKINPORT_CLIENT_SECRET = ENV["SKINPORT_CLIENT_SECRET"]

mainloop(ENV["PRICE"].to_f || 0, item_list, request_interval_seconds)