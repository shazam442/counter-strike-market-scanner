require_relative './skinportapi.rb'
require_relative './steamscraper.rb'
require_relative './skinbaronapi.rb'

require 'json'
require 'httparty'
require 'dotenv/load'
require 'byebug'
require 'colorize'

def loading_time seconds
    timer = "[#{"-"*seconds}]\r"
    for i in 0..seconds do
        print timer
        timer.sub!("-","*")
        10.times { sleep 0.1 }
    end
end

def getAllListings(skinbaronApi, skinportApi)
    result = Array.new
    result << skinbaronApi.getListings << skinportApi.getListings

rescue => e
    byebug
end

def mainloop(price_alert, item_list)
    skinportApi = Skinport.new(SKINPORT_CLIENT_ID, SKINPORT_CLIENT_SECRET)
    skinbaronApi = SkinbaronApi.new(SKINBARON_API_KEY, item_list)
    
    system("clear")
    while true
        steam_listings = SteamScraper.getListings.reject { |l| l[:price].nil? }
        steam_price = steam_listings.min_by { |l| l[:price] }

        listings = getAllListings(skinbaronApi, skinportApi)

        system("clear"); sleep(1)

        puts "Buying for: #{price_alert}"
        puts "Skinbaron Balance: " << "#{skinbaronApi.getBalance.to_f} €".green
        puts "Steam Price Reference: " << "#{steam_price&.[] :price} € - #{steam_price&.[] :item_name}".yellow
        puts listings

        listings.each do |listing|
            next if !listing.instance_of?(Hash) || !listing[:price].instance_of?(Float)
            next if listing[:price] > price_alert
            if listing[:price] <= price_alert
                if listing[:source] == 'Skinbaron'
                    puts "Buying Item..."
                    r = skinbaronApi.buyItem(listing[:price], listing[:id])
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