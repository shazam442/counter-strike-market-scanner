require 'json'
require 'httparty'
require 'dotenv/load'
require 'byebug'
require 'colorize'

require_relative './steamscraper.rb'
module API
    require_relative './accessors/skinport.rb'
    require_relative './accessors/skinbaron.rb'
end

def loading_time seconds
    timer = "[#{"-"*seconds}]\r"
    for i in 0..seconds do
        print timer
        timer.sub!("-","*")
        10.times { sleep 0.1 }
    end
end

def getAllListings(skinbaron, skinport)
    result = Array.new
    result << skinbaron.getListings << skinport.getListings

    # result.sort_by { |_key, value| -value}
end

def mainloop(price_alert, item_list)
    skinport = API::Skinport.new(SKINPORT_CLIENT_ID, SKINPORT_CLIENT_SECRET, item_list)
    skinbaron = API::Skinbaron.new(SKINBARON_API_KEY, item_list)
    
    system("clear")
    while true
        steam_listings = SteamScraper.getListings.reject { |l| l[:price].nil? }
        steam_price = steam_listings.min_by { |l| l[:price] }

        listings = getAllListings(skinbaron, skinport)

        system("clear"); sleep(1)

        puts "Buying for: #{price_alert}"
        puts "Skinbaron Balance: " << "#{skinbaron.getBalance.to_f} €".green
        puts "Steam Price Reference: " << "#{steam_price&.[] :price} € - #{steam_price&.[] :item_name}".yellow
        puts listings

        listings.each do |listing|
            next if !listing.instance_of?(Hash) || !listing[:price].instance_of?(Float)
            next if listing[:price] > price_alert
            if listing[:price] <= price_alert
                if listing[:source] == 'Skinbaron'
                    puts "Buying Item..."
                    r = skinbaron.buyItem(listing[:price], listing[:id])
                    puts r
                    return mainloop(price_alert)
                end
            end
        end

        loading_time 30
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
rescue => e
    byebug
end