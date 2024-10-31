require_relative './accessors/skinport'
require_relative './accessors/skinbaron'

def mainloop(config)
    config => {
        targets:,
        target_price:,
        request_interval_seconds:,
        env: {
            skinbaron_api_key:,
            skinport_client_id:,
            skinport_client_secret:
        }
    }
    target_price = target_price.to_f

    logger = Logger.new("logs/app.log", 1)
    skinbaron = API::Skinbaron.new(skinbaron_api_key, targets)
    skinport = API::Skinport.new(skinport_client_id, skinport_client_secret, targets)
    # steam = API::Steam.new(targets)
    
    system("clear")-
    while true
        # steam_listings = steam.getListings
        # steam_price = steam_listings.min_by { |l| l[:price] }

        skinbaron_balance_EUR = skinbaron.getBalance.to_f
        listings = getAllListings(skinbaron, skinport, logger)

        system("clear"); sleep(1)

        puts "Buying for: #{target_price}"
        puts "Skinbaron Balance: " << "#{skinbaron_balance_EUR} €".green
        # puts "Steam Price Reference: " << "#{steam_price&.[] :price} € - #{steam_price&.[] :item_name}".yellow
        puts listings

        target_price_matches = filterByTargetPrice(listings, target_price)
        purchaseItems(target_price_matches, skinbaron, skinbaron_balance_EUR) # skinport does not allow purchase via api

        loadingBar request_interval_seconds
    end
rescue SocketError, Net::OpenTimeout => e
    logger.fatal(e)
    system('clear') && puts("COULD NOT ESTABLISH CONNECTION")
    loadingBar request_interval_seconds
    mainloop(config)
end

def purchaseItems(listings, skinbaron, balance)
    listings.each do |listing|
        puts "Buying Item..."
        r = skinbaron.buyItem(listing[:price], listing[:id])
        puts r
    end
end

def filterByTargetPrice(listings, target_price)
    listings.select { |l| (l in { source: 'Skinbaron', price: Float => price }) && price <= target_price }
end

def getAllListings(skinbaron, skinport, logger)
    result = Array.new
    result
        .concat(skinbaron.getListings)
        .concat(skinport.getListings)

    logger.debug(JSON.pretty_generate(["getAllListings uncleaned Result"].concat(result)))
    
    cleaned_result = result.select do |listing|
        next unless listing.is_a? Hash
        next if listing[:price].nil?
        true
    end
    
    cleaned_result.sort_by { |listing| listing[:price] }
end

def loadingBar seconds
    timer = "[#{"-"*seconds}]\r"
    for _ in 0..seconds do
        print timer
        timer.sub!("-","*")
        10.times { sleep 0.1 }
    end
end
