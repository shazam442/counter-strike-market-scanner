class SkinbaronApi
    def initialize(api_key, item_list)
        @base_url = 'https://api.skinbaron.de'
    
        @item_list = item_list
        
        @base_headers = {
            "Content-Type" => "application/json",
            "x-requested-with" => "XMLHttpRequest"
        }
        @base_body = {
            :apikey => api_key
        }
    end

    def getBalance
        response = post(endpoint: "GetBalance").to_h
        response[:balance]
    end

    def getListings 
        listings = @item_list.map { |i| getCheapestListing(i) }
        listings.compact
    rescue
        byebug
    end

    def buyItem(price, id)
        buyLogger("#{Time.now.round}\n Attempting to Buy Item #{id} for #{price}:\n")

        body = {
            total: price,
            toInventory: true,
            saleids: [id]
        }
        response = post(endpoint: "BuyItems", body: body )
        buyLogger("#{response}\n\n")

        response  
    end

    private

    def post(params = {})
        raise "Endpoint path must be specified" if params[:endpoint].nil?

        body = @base_body
            .merge(params[:body] || {})
            .to_json
        headers = @base_headers.merge(params[:headers] || {})
        url_to_endpoint = "#{@base_url}/#{params[:endpoint]}"
    
        HTTParty.post(
            url_to_endpoint,
            :body => body,
            :headers => headers,
        )
    end

    def getCheapestListing item_name
        body = {
            appid: 730,
            search_item: item_name,
            tradelocked: true,
            souvenir: false,
            items_per_page: 0
        }
        response = post(endpoint: "Search", body: body)
        return 'TOO MANY REQUESTS' if response.code == 429

        items = response.to_h["sales"]
        wear_filtered_items = items.select do |item|
            item["wear"] < 0.07 # Factory New
        end

        cheapest = wear_filtered_items.min_by { |item| item["price"]}
        return {
            price: cheapest["price"],
            source: 'Skinbaron',
            item_name: cheapest['market_name'],
            id: cheapest['id']
        }
    end

    def buyLogger(message)
        File.write(File.join(File.dirname(__FILE__), '../logs/buy_log.txt'), message, mode: 'a')
    end
end
