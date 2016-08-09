NPR.configure do |config|
  config.apiKey = ENV['NPR_API_KEY'] # for account b.li@columbia.edu
  config.sort = 'date descending'
  config.requiredAssets = 'text'
end
