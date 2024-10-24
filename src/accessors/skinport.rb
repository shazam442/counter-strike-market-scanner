require 'base64'

module API
class Skinport
    attr_reader :last_fetched_listings
    attr_accessor :item_list

    def initialize(client_id, client_secret, item_list)
        verifyInitParams(client_id, client_secret, item_list)
        @BASE_API_URL = "https://api.skinport.com/v1"
        @base_headers = {
            "Content-Type" => "application/json",
            "Authorization": generateAuthHeader(client_id, client_secret)
        }
        @base_body = {
            currency: 'EUR'
        }
        @item_list = item_list
        @last_item_fetch_time = Time.now
    end

    def getListings
        return @last_fetched_listings if @last_item_fetch_time <= (Time.now - 5 * 60) # skinport endpoint is cached by 5 minutes
        
        deny_array = [ 'Souvenir', 'StatTrak' ]
        @last_fetched_listings = fetchListings({allow_array: @item_list, deny_array: deny_array})
    end

    private

    def get(params = {})
        raise "Endpoint must be specified" if params[:endpoint].nil?
        url_to_endpoint = "#{@BASE_API_URL}/#{params[:endpoint]}"
        headers = @base_headers.merge(params[:headers] || {} )
        body = @base_body.merge(params[:body] || {} ).to_json

        HTTParty.get(
            url_to_endpoint,
            headers: headers,
            body: body, :debug_output => $stdout
        )
    end

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

    def fetchListings(params = {})
        allow_array = params[:allow_array]
        deny_array = params[:deny_array]
    
        @last_item_fetch_time = Time.now
        
        response = get(endpoint: "items")
        byebug unless response.success?

        allItems = JSON.parse response.body

        allowed_items = allItems.select do |item|
            allow_array.any? do |allowedString|
                item['market_hash_name'][allowedString]
            end
        end

        allowed_items_filtered = allowed_items.reject do |item|
            deny_array.any? do |deniedString|
                item['market_hash_name'][deniedString]
            end
        end
        
        allowed_items_filtered_sorted = allowed_items_filtered.sort_by { |item| item['market_hash_name'] }
        transform_data(allowed_items_filtered_sorted)
    end

    def verifyInitParams(client_id, client_secret, item_list)
        raise "check instanciation parameters" if client_id.empty? || client_secret.empty? || item_list.empty? || !item_list.is_a?(Array)
        raise("CLIENT ID ABNORMALLY SHORT. PLEASE CHECK YOUR CLIENT ID") unless client_id.length >= 20
        raise("CLIENT SECRET ABNORMALLY SHORT. PLEASE CHECK YOUR CLIENT SECRET") unless client_secret.length >= 30
    end
end
end