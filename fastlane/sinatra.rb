require 'sinatra'

post '/push/:udid/:bundle_id' do
  push_data_file = 'push_payload.json'
  File.open(push_data_file, 'w') { |f| f.write(request.body.read) }
  puts `xcrun simctl push #{params['udid']} #{params['bundle_id']} #{push_data_file}`
end
