require 'httparty'
require 'nokogiri'

class SteamScraper 
    @name = 'SteamScraper'
    def self.getListings
        method_names = [:mp9, :usp, :m249, :sg553]
        result = []

        method_names.each do |method_name|
            begin
                result << self.send(method_name)
            rescue 
                result << {
                    item_name: "#{method_name.to_s} failed",
                    price: 9999,
                    source: "Steam"
                }
            end
        end
        result.compact
    end

    def self.m249
        url = 'https://steamcommunity.com/market/listings/730/M249%20%7C%20Humidor%20%28Factory%20New%29/render?currency=3'
        response = HTTParty.get url
        response = JSON.parse response.body

        html = response["results_html"]
        doc = Nokogiri::HTML html
        listings = doc.css(".market_listing_price.market_listing_price_with_fee")

        prices = listings.map do |l|
            next 99999 if l.text["Sold"]
            l.text.gsub("-","0")[/\d+,\d+/].sub(",",".").to_f
        end

        price_hash = {
            item_name: "M249 | Humidor (Factory New)",
            price: prices.min,
            source: "Steam"
        }
    end

    def self.mp9
        url = 'https://steamcommunity.com/market/listings/730/MP9%20%7C%20Music%20Box%20%28Factory%20New%29/render?currency=3'
        response = HTTParty.get url
        response = JSON.parse response.body

        html = response["results_html"]
        doc = Nokogiri::HTML html
        listings = doc.css(".market_listing_price.market_listing_price_with_fee")

        prices = listings.map do |l|
            next 99999 if l.text["Sold"]
            l.text.gsub("-","0")[/\d+,\d+/].sub(",",".").to_f
        end

        price_hash = {
            item_name: "MP9 | Music Box (Factory New)",
            price: prices.min,
            source: "Steam"
        }
    end

    def self.usp
        url = 'https://steamcommunity.com/market/listings/730/USP-S%20%7C%20Purple%20DDPAT%20%28Factory%20New%29/render?currency=3'
        response = HTTParty.get url
        response = JSON.parse response.body

        html = response["results_html"]
        doc = Nokogiri::HTML html
        listings = doc.css(".market_listing_price.market_listing_price_with_fee")

        prices = listings.map do |l|
            next 99999 if l.text["Sold"]
            l.text.gsub("-","0")[/\d+,\d+/].sub(",",".").to_f
        end

        price_hash = {
            item_name: "USP-S | Purple DDPAT (Factory New)",
            price: prices.min,
            source: "Steam"
        }
    end

    def self.sg553
        url = 'https://steamcommunity.com/market/listings/730/SG%20553%20%7C%20Desert%20Blossom%20%28Factory%20New%29/render?currency=3'
        response = HTTParty.get url
        response = JSON.parse response.body

        html = response["results_html"]
        doc = Nokogiri::HTML html
        listings = doc.css(".market_listing_price.market_listing_price_with_fee")

        prices = listings.map do |l|
            next 99999 if l.text["Sold"]
            l.text.gsub("-","0")[/\d+,\d+/].sub(",",".").to_f
        end

        price_hash = {
            item_name: "SG 553 | Desert Blossom (Factory New)",
            price: prices.min,
            source: "Steam"
        }
    end
end