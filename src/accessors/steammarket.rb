require 'httparty'
require 'json'
require 'logger'
require_relative '../helpers/float_wear_helper'

module API
  class SteamMarket
    include FloatHelper
    
    def initialize(config)
      @base_url = 'https://steamcommunity.com/market/priceoverview'
      @base_params = { currency: 3, appid: 730 }
      @base_headers = {
        "Content-Type" => "application/json",
        "x-requested-with" => "XMLHttpRequest",
        "Connection" => "keep-alive"
      }

      @logger = Logger.new('logs/steammarket.log', 1)

      @item_list = applyWearLevelsToItemNames(config)
    end

    def getListings
      @item_list.map do |item|
        response = fetchPriceOverview(item)
        price = response["lowest_price"].sub("€", "").sub(",", ".").to_f
        sleep(0.2)
        
        buildItemPriceHash(item, price)
      end
    end

    # def getPriceReferences
    #   @item_list.map do |item|
    #     response = fetchPriceOverview(item)
        
    # end

    private

    def buildItemPriceHash(item, price) = { source: 'SteamMarket', price: price, item_name: item }
    
    def fetchPriceOverview(market_hash_name)
      raise "Item must be specified" if market_hash_name.nil?
      
      body = @base_params.merge( market_hash_name: market_hash_name )
      url = "#{@base_url}?#{URI.encode_www_form(body)}"
      
      response = HTTParty.get(url)
      logResponse(response, market_hash_name)
      raise "Failed to fetch data: #{response.code} #{response.message}" unless response.success? && response.to_h["success"] == true

      response.to_h
    end

    def applyWearLevelsToItemNames(config)
      wear_levels = float_range_to_wear_levels(config[:targets][:min_wear], config[:targets][:max_wear])
      
      wear_levels.map do |wear|
        config[:targets][:item_list].map { |item| "#{item} (#{wear})" }
      end.flatten
    end
    
    def logResponse(response, item)
      @logger.debug(
        JSON.pretty_generate({
          source: "#{self.class.to_s}/#{item}",
          code: "#{response.code} #{response.message}",
          body: response
        })
      )
    rescue
      @logger.error([response, item])
    end
  end
end
