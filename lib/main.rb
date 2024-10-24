require 'json'
require 'httparty'
require 'dotenv/load'
require 'byebug'
require 'colorize'
require 'logger'

require_relative './accessors/steamscraper.rb'
require_relative './accessors/skinport.rb'
require_relative './accessors/skinbaron.rb'

def mainloop(price_alert, item_list, request_interval_seconds)
    skinport = API::Skinport.new(SKINPORT_CLIENT_ID, SKINPORT_CLIENT_SECRET, item_list)
    skinbaron = API::Skinbaron.new(SKINBARON_API_KEY, item_list)
    
    system("clear")
    while true
        steam_listings = SteamScraper.getListings.reject { |l| l[:price].nil? }
        steam_price = steam_listings.min_by { |l| l[:price] }

        skinbaron_balance_EUR = skinbaron.getBalance.to_f
        listings = getAllListings(skinbaron, skinport)

        system("clear"); sleep(1)

        puts "Buying for: #{price_alert}"
        puts "Skinbaron Balance: " << "#{skinbaron_balance_EUR} €".green
        puts "Steam Price Reference: " << "#{steam_price&.[] :price} € - #{steam_price&.[] :item_name}".yellow
        puts listings

        priceAlertMatches = filterByPriceAlert(listings, price_alert)
        purchaseItems(priceAlertMatches, skinbaron, skinbaron_balance_EUR) # skinport does not allow purchase via api

        requestDelaySeconds request_interval_seconds
    end
rescue SocketError, Net::OpenTimeout
    system('clear') && puts("COULD NOT ESTABLISH CONNECTION")
    requestDelaySeconds request_interval_seconds
    mainloop(price_alert, item_list, request_interval_seconds)
end

def purchaseItems(listings, skinbaron, balance)
    listings.each do |listing|
        next unless listing[:source] == 'Skinbaron'
        puts "Buying Item..."
        r = skinbaron.buyItem(listing[:price], listing[:id])
        puts r
    end
end

def filterByPriceAlert(listings, price_alert)
    listings.select do |l|
        l.is_a?(Hash) && l[:price].is_a?(Float) && l[:price] <= price_alert
    end
end

def getAllListings(skinbaron, skinport)
    result = Array.new
    result
        .concat(skinbaron.getListings)
        .concat(skinport.getListings)
    
    cleaned_result = result.select { |listing| not listing[:price].nil? }
    
    cleaned_result.sort_by { |listing| listing[:price] }
end

def requestDelaySeconds seconds
    timer = "[#{"-"*seconds}]\r"
    for _ in 0..seconds do
        print timer
        timer.sub!("-","*")
        10.times { sleep 0.1 }
    end
end
