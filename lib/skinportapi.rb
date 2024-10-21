require 'base64'

class Skinport
    attr_reader :listings

    def initialize(client_id, client_secret)
        @SKINPORT_API = "https://api.skinport.com/v1"
        @AUTH_HEADER_STRING = nil
        @listings = nil

        self.setAuthHeader(client_id, client_secret)
        self.getListings
    end

    def getListings
        @listings = self.fetchListings(
            [
                'M249 | Humidor (Factory New)',
                'USP-S | Purple DDPAT (Factory New)',
                'SG 553 | Desert Blossom (Factory New)',
                'MP9 | Music Box (Factory New)'
            ],
            [
                'Souvenir',
                'StatTrak'
            ],
        )
        @listings
    rescue
        "SKINPORT GET ITEMS EXCEPTION!"
    end

    private

    def setAuthHeader(client_id, client_secret)
        clientData = "#{client_id}:#{client_secret}"
        encodedData = Base64.encode64(clientData).gsub "\n",""
        
        @AUTH_HEADER_STRING = "Basic #{encodedData}"
    end

    def transform_data listings
        listings.map! do |listing|
            listing
                .slice('market_hash_name', 'min_price')
                .merge({'price' => listing['min_price'], 'source' => 'Skinport', 'item_name' => listing['market_hash_name']})
                .except('min_price','market_hash_name')
        end

        # convert keys to symbols
        listings.each do |listing|
            listing.keys.each do |key|
                listing[(key.to_sym rescue key) || key] = listing.delete(key)
            end
        end
    end

    def fetchListings allowArray=[], denyArray=[]
        response = getRequest 'items'
        allItems = JSON.parse response.body

        allowed_items = allItems.select do |item|
            allowArray.any? do |allowedString|
                item['market_hash_name'][allowedString]
            end
        end

        allowed_items_filtered = allowed_items.reject do |item|
            denyArray.any? do |deniedString|
                item['market_hash_name'][deniedString]
            end
        end
        
        allowed_items_filtered_sorted = allowed_items_filtered.sort_by { |item| item['market_hash_name'] }
        transform_data(allowed_items_filtered_sorted)
    end

    def getRequest endpoint, sales_query=nil
        if endpoint == 'items'
            HTTParty.get(
                "#{@SKINPORT_API}/items",
                headers: {
                    'Authorization': @AUTH_HEADER_STRING
                },
                params: {
                    currency: 'EUR'
                }
            )
        elsif endpoint == 'sales'
            HTTParty.get(
                "#{@SKINPORT_API}/sales/history",
                headers: {
                    'Authorization': @AUTH_HEADER_STRING
                },
                params: {
                    app_id: 730,
                    currency: 'EUR',
                    item_name: sales_query
                }
            )
        end
    end
end
