require_relative './lib/main.rb'

item_list = [
    "M249 | Humidor",
    "SG 553 | Desert Blossom",
    "USP-S | Purple DDPAT",
    "MP9 | Music Box"
]

SKINBARON_API_KEY = ENV['SKINBARON_API_KEY']

SKINPORT_CLIENT_ID = ENV["SKINPORT_CLIENT_ID"]
SKINPORT_CLIENT_SECRET = ENV["SKINPORT_CLIENT_SECRET"]

mainloop(ENV["PRICE"].to_f || 0, item_list)