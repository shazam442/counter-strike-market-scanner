module API
class Skinbaron
    def initialize(api_key, targets)
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
            getCheapestListingForEachWearLevel(i)
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

    def getCheapestListingForEachWearLevel item_name
        body = {
            appid: 730,
            search_item: item_name,
            min_wear: @min_wear,
            max_wear: @max_wear,
            souvenir: false,
            items_per_page: 99
        }
    
        item_list = []
        
        response = post(endpoint: "Search", body: body)
        return {error: 'TOO MANY REQUESTS', source: 'Skinbaron'} if response.code == 429

        item_list.concat(response.to_h["sales"])
        item_list = response.to_h["sales"]

        item_list.select! { |item| item["price"] != 0 } # remove items with no price
        return nil if item_list.empty? # return nil if no items are found
        item_list.select! { |item| itemWithinWearLimits(item) } # remove items that are not within wear limits
        
        # min by price for each wear level outputs a hash of wear level => item
        wear_filtered_items = grouped_item_list.map do |wear, items|
            items.min_by { |item| item["price"] }
        end
        
        
        # group by wear level substring within market_name
        grouped_item_list = wear_filtered_items.group_by { |item| item["market_name"].match(/\(([^)]+)\)/)[1] }
        
        cheapest = wear_filtered_items.flatten.min_by do |item|
            debugger if item.is_a? Array
            item["price"]
        end
        byebug if cheapest.nil?
        return {
            price: cheapest["price"],
            wear: cheapest["wear"],
            source: 'Skinbaron',
            item_name: cheapest['market_name'],
            id: cheapest['id']
        }
    end

    def itemWithinWearLimits(item) = item["wear"] <= @max_wear && item["wear"] >= @min_wear

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
end
end