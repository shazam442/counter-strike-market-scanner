module API
class Skinbaron
    attr_accessor :item_list
    
    def initialize(api_key, item_list)
        verifyInitParams(api_key, item_list)
        @base_url = 'https://api.skinbaron.de'
    
        @item_list = item_list
        
        @base_headers = {
            "Content-Type" => "application/json",
            "x-requested-with" => "XMLHttpRequest"
        }
        @base_body = {
            :apikey => api_key
        }
        @logger = Logger.new('logs/app.log', 1)
    end

    def getBalance
        response = post(endpoint: "GetBalance").to_h
        response[:balance]
    end

    def getListings
        listings = @item_list.map { |i| getCheapestListing(i) }
        listings.compact
    end

    def buyItem(price, id)
        @logger.info("#{Time.now.round}\n Attempting to Buy Item #{id} for #{price}:\n")

        body = {
            total: price,
            toInventory: true,
            saleids: [id]
        }
        post(endpoint: "BuyItems", body: body )
    end

    private

    def post(params = {})
        raise "Endpoint must be specified" if params[:endpoint].nil?

        body = @base_body
            .merge(params[:body] || {})
            .to_json
        headers = @base_headers.merge(params[:headers] || {})
        url_to_endpoint = "#{@base_url}/#{params[:endpoint]}"
    
        response = HTTParty.post(url_to_endpoint, :body => body, :headers => headers)

        logResponse(response, params[:endpoint])
        response
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
        return {error: 'TOO MANY REQUESTS', source: 'Skinbaron'} if response.code == 429

        items = response.to_h["sales"]
        wear_filtered_items = items.select do |item|
            item["wear"] < 0.07 # Factory New
        end

        
        cheapest = wear_filtered_items.min_by { |item| item["price"]} || {}
        byebug if cheapest.nil?
        return {
            price: cheapest["price"],
            source: 'Skinbaron',
            item_name: cheapest['market_name'],
            id: cheapest['id']
        }
    end

    def logResponse(response, endpoint)
        @logger.debug(
            JSON.pretty_generate({
                source: "#{self.class.to_s}/#{endpoint}",
                code: "#{response.code.to_s} #{response.message}",
                body: response.to_h
            })
        )
    end

    def verifyInitParams(api_key, item_list)
        raise "check instanciation parameters" if api_key.empty? || item_list.empty? || !item_list.is_a?(Array)
        raise("API KEY LENGTH ABNORMALLY SHORT. PLEASE CHECK YOUR API KEY") unless api_key.length >= 30
    end
end
end