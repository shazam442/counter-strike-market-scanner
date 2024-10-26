module API
class Skinbaron
    attr_accessor :item_list
    
    def initialize(api_key, targets)
        verifyInitParams(api_key, targets)
        @base_url = 'https://api.skinbaron.de'
    

        
        @item_list = targets[:item_list]
        @min_wear, @max_wear = targets[:min_wear], targets[:max_wear]
        
        @base_headers = {
            "Content-Type" => "application/json",
            "x-requested-with" => "XMLHttpRequest",
            "Connection" => "keep-alive"
        }
        @base_body = {
            :apikey => api_key
        }
        @logger = Logger.new('logs/skinbaron.log', 1)
    end

    def getBalance
        response = post(endpoint: "GetBalance").to_h
        response[:balance]
    end

    def getListings
        listings = @item_list.map do |i|
            sleep(1)
            getCheapestListing(i)
        end
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

        logResponse(response, params[:endpoint], params[:body])
        response
    end

    def getCheapestListing item_name
        body = {
            appid: 730,
            search_item: item_name,
            tradelocked: true,
            stattrak: true,
            souvenir: false,
            items_per_page: 0
        }
        response = post(endpoint: "Search", body: body)
        return {error: 'TOO MANY REQUESTS', source: 'Skinbaron'} if response.code == 429

        items = response.to_h["sales"]
        wear_filtered_items = items.select do |item|
            item["wear"] <= @max_wear && item["wear"] >= @min_wear

        end

        
        cheapest = wear_filtered_items.min_by { |item| item["price"]} || {}
        byebug if cheapest.nil?
        return {
            price: cheapest["price"],
            wear: cheapest["wear"],
            source: 'Skinbaron',
            item_name: cheapest['market_name'],
            id: cheapest['id']
        }
    end

    def logResponse(response, endpoint, request_body)
        @logger.debug(
            JSON.pretty_generate({
                source: "#{self.class.to_s}/#{endpoint}",
                code: "#{response.code.to_s} #{response.message}",
                request_payload: request_body,
                response_body: response.to_s.start_with?("{") ? response.to_h : response
            })
        )
    end

    def verifyInitParams(api_key, targets)
        raise "check instanciation parameters" unless targets in { item_list: Array , min_wear: Numeric, max_wear: Numeric }
        raise("CHECK API KEY LENGTH AND VALIDITY") if api_key.length <= 30 || api_key.empty?
    end
end
end