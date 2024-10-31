def validateConfig(config)
    raise "check instanciation parameters" unless config in {
        targets: {
            item_list: Array,
            min_wear: Numeric,
            max_wear: Numeric
        },
        target_price: Numeric,
        request_interval_seconds: Numeric,
        env: {
            skinbaron_api_key: String,
            skinport_client_id: String,
            skinport_client_secret: String
        }
    }

    item_list = config[:targets][:item_list]
    raise "item_list must contain at least one item" if item_list.empty?
    raise "Item list must contain only non-empty strings" unless item_list.all? { |it| it.is_a?(String) && it.length > 0 }

    config[:env].each do |key, value|
        raise "env variable #{key} is empty" if value.empty?
    end
end

def getConfig
  default_config = {
    targets: [],
    target_price: 0,
    request_interval_seconds: 60,
    env: {
        "skinbaron_api_key": ENV['SKINBARON_API_KEY'],
        "skinport_client_id": ENV["SKINPORT_CLIENT_ID"],
        "skinport_client_secret": ENV["SKINPORT_CLIENT_SECRET"]
    }
  }

  file = File.read("config.json")
  file_config = JSON.parse(file).transform_keys(&:to_sym)
  file_config[:targets].transform_keys!(&:to_sym)

  config = default_config.merge file_config
  validateConfig(config)

  config
end
