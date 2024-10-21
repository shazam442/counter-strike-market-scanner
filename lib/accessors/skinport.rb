require 'base64'

class Skinport
    attr_reader :last_fetched_listings

    attr_accessor :item_list
    

    def initialize(client_id, client_secret, item_list)
        @BASE_API_URL = "https://api.skinport.com/v1"
        @base_headers = {
            "Content-Type" => "application/json",
            "Authorization": generateAuthHeader(client_id, client_secret)
        }
        @base_body = {
            currency: 'EUR'
        }
        @item_list = item_list
    end

    def getListings
        denyArray = [ 'Souvenir', 'StatTrak' ]
        @last_fetched_listings = fetchListings({allowArray: @item_list, denyArray: denyArray})
    end

    private

    def generateAuthHeader(client_id, client_secret)
        clientData = "#{client_id}:#{client_secret}"
        encodedData = Base64.encode64(clientData).gsub "\n",""
        
        "Basic #{encodedData}"
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

    def get(params = {})
        raise "Endpoint must be specified" if params[:endpoint].nil?

        HTTParty.get(
            "#{@BASE_API_URL}/#{params[:endpoint]}",
            headers: @base_headers.merge(params[:headers] || {} ),
            body: @base_body.merge(params[:body] || {} )
        )
    end
end
