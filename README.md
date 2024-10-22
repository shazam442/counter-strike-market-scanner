# Market Scanner for Counter Strike 2

This repo contains a ruby script which monitors 3 different marketplaces for CS2 Skins (_rare_ cosmetic ingame items listed for real money). It can also automatically purchase selected items whenever their price drops below a threshold/price. Notifications on threshold breach are yet to implement.

2 marketplaces are accessed via their Rest APIs (Skinbaron, Skinport) and 1 is web scraped (Steam Community Market)

The script fetches data from Steam and Skinbaron every 60 seconds.
Since the Skinport API caches its endpoints for 5 minutes and heavily limits request rate (8 requests per 5 minutes) its data is fetched every 5 minutes.

Automatic purchases can only be done for items listed on Skinbaron.  
The Skinport API does not offer an endpoint for purchasing items.  
The Steam Market would have to be accessed via browser automation, which is not implemented (yet), since it does not provide an API at all.

The specific items to be monitored are currently hardcoded and will be customizable in the future.

API Keys for both Skinbaron and Skinport need to be specified into `.env` file to run this script. You can copy the `.env.example` file and rename it.

Start the script with the following command below.  
`PRICE=x` sets the price an item must fall below in order to trigger automatic purchase.  

`PRICE=0 ruby start_bot.rb`

Omitting `PRICE` or setting it to `0` will effectively disable automatic purchases.