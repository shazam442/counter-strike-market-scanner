require 'json'
require 'httparty'
require 'dotenv/load'
require 'byebug'
require 'colorize'

require_relative './steamscraper.rb'
require_relative './accessors/skinport.rb'
require_relative './accessors/skinbaron.rb'

def mainloop(price_alert, item_list)
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
        purchaseItems(priceAlertMatches, skinbaron, balance) # skinport does not allow purchase via api

        loading_time 60
    end
rescue SocketError, Net::OpenTimeout
    system('clear') && puts("COULD NOT ESTABLISH CONNECTION")
    loading_time(5)
    mainloop(price_alert)
rescue JSON::ParserError => e
    if e.message.include? "Bad authenticity token"
        pp "STACK TRACE", e.backtrace
        raise "Bad Authenticity Token"
    end
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
    result << skinbaron.getListings << skinport.getListings
    
    # result.sort_by { |_key, value| -value}
end

def loading_time seconds
    timer = "[#{"-"*seconds}]\r"
    for _ in 0..seconds do
        print timer
        timer.sub!("-","*")
        10.times { sleep 0.1 }
    end
end
