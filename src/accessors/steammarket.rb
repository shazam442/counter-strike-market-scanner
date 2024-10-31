require 'httparty'
require 'json'
require 'logger'

module API
  class SteamMarket
    def initialize(config)
      @base_url = 'https://steamcommunity.com/market/search/render'
      @item_list = config[:targets][:item_list]
      @min_wear = config[:targets][:min_wear]
      @max_wear = config[:targets][:max_wear]
      @logger = Logger.new('logs/steammarket.log', 1)
    end

    def getListings
      @item_list.each do |item|
        response = get(query: item)
        listings = response["results"]
        logResponse(response, item)
        # Process listings as needed
      end
    end

    private

    def get(params = {})
      raise "Query must be specified" if params[:query].nil?

      url = "#{@base_url}?norender=1&start=0&count=99&appid=730&query=#{params[:query]}"
      response = HTTParty.get(url)
      raise "Failed to fetch data: #{response.code} #{response.message}" unless response.success?

      response.to_h
    end

    def logResponse(response, query)
      @logger.debug(
        JSON.pretty_generate({
          source: "#{self.class.to_s}/#{query}",
          code: "#{response.code.to_s} #{response.message}",
          body: response.to_s.start_with?("[") ? response.to_a : response
        })
      )
    rescue
      @logger.error(response, query)
    end
  end
end
