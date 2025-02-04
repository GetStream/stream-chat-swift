require 'net/http'
require 'json'
require 'securerandom'
require 'faye/websocket'
require 'eventmachine'
require 'uri'

STREAM_BASE_URL = 'chat.stream-io-api.com'
STREAM_HTTP_URL = "https://#{STREAM_BASE_URL}"
STREAM_WSS_URL = "wss://#{STREAM_BASE_URL}/connect"
STREAM_DEMO_API_KEY = '8br4watad788'
STREAM_DEMO_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0'
STREAM_USER_ID = 'luke_skywalker'
STREAM_HEADERS = {
  'Authorization' => STREAM_DEMO_TOKEN,
  'Stream-Auth-Type' => 'jwt',
  'Content-Type' => 'application/json'
}
MOCK_SERVER_FIXTURES_PATH = '../TestTools/StreamChatTestMockServer/Fixtures/JSONs'
TEST_TOOLS_FIXTURES_PATH = '../TestTools/StreamChatTestTools/Fixtures/Images'

def connect_endpoint
  payload = {
    user_id: STREAM_USER_ID,
    user_details: {
      id: STREAM_USER_ID,
      name: 'Luke Skywalker',
      image: 'https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg',
      birthland: 'Tatooine'
    },
    server_determines_connection_id: true
  }.to_json
  query_params = ["api_key=#{STREAM_DEMO_API_KEY}", "json=#{URI.encode_www_form_component(payload)}"]
  "#{STREAM_WSS_URL}?#{query_params.join('&')}"
end

def establish_websocket_connection(event_data)
  health_check = JSON.parse(event_data)
  health_check['me']['channel_mutes'] = []
  health_check['me']['mutes'] = []
  health_check['me']['devices'] = []
  save_json(health_check, 'ws_health_check.json')
  health_check['connection_id']
end

def request_channels(connection_id)
  payload = {
    filter_conditions: {
      members: { '$in': [STREAM_USER_ID] }
    },
    limit: 20,
    member_limit: 30,
    message_limit: 25,
    watch: true
  }.to_json
  query_params = [
    "api_key=#{STREAM_DEMO_API_KEY}",
    "connection_id=#{connection_id}",
    "payload=#{URI.encode_www_form_component(payload)}"
  ]
  endpoint = "#{STREAM_HTTP_URL}/channels?#{query_params.join('&')}"
  response = http_get(endpoint)
  response['channels'] = [response['channels'][0]]
  response['channels'][0]['members'].each_with_index do |member, i|
    response['channels'][0]['read'][i] = {}
    response['channels'][0]['read'][i]['user'] = member['user']
    response['channels'][0]['read'][i]['unread_messages'] = 0
    response['channels'][0]['read'][i]['last_read'] = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
  end

  save_json(response, 'http_channels.json')
end

def send_typing_event(channel_id)
  payload = { event: { type: 'typing.start' } }.to_json
  endpoint = "#{STREAM_HTTP_URL}/channels/messaging/#{channel_id}/event?api_key=#{STREAM_DEMO_API_KEY}"
  response = http_post(endpoint, payload)
  save_json(response, 'http_events.json')
end

def send_message(channel_id, text, filename)
  message_id = SecureRandom.uuid
  payload = {
    message: {
      id: message_id,
      show_in_channel: false,
      pinned: false,
      silent: false,
      text: text
    }
  }.to_json
  endpoint = "#{STREAM_HTTP_URL}/channels/messaging/#{channel_id}/message?api_key=#{STREAM_DEMO_API_KEY}"
  response = http_post(endpoint, payload)
  save_json(response, filename)
  message_id
end

def send_youtube_link(channel_id)
  send_message(channel_id, 'https://youtube.com/watch?v=xOX7MsrbaPY', 'http_youtube_link.json')
end

def send_ephemeral_message(channel_id)
  send_message(channel_id, '/giphy Test', 'http_message_ephemeral.json')
end

def send_unsplash_link(channel_id)
  send_message(channel_id, 'https://unsplash.com/photos/1_2d3MRbI9c', 'http_unsplash_link.json')
end

def send_giphy_link(channel_id)
  send_message(channel_id, 'https://giphy.com/gifs/test-gw3IWyGkC0rsazTi', 'http_giphy_link.json')
end

def create_channel(connection_id)
  payload = {
    data: {
      members: [STREAM_USER_ID, 'han_solo', 'count_dooku'],
      name: 'Sync Mock Server'
    },
    presence: true,
    state: true,
    watch: true,
    messages: { limit: 25 }
  }.to_json
  channel_id = SecureRandom.uuid
  query_params = ["api_key=#{STREAM_DEMO_API_KEY}", "connection_id=#{connection_id}"]
  endpoint = "#{STREAM_HTTP_URL}/channels/messaging/#{channel_id}/query?#{query_params.join('&')}"
  response = http_post(endpoint, payload)
  save_json(response, 'http_channel_creation.json')
  channel_id
end

def add_reaction(message_id)
  payload = {
    enforce_unique: false,
    reaction: {
      type: 'like',
      score: 1
    }
  }.to_json
  endpoint = "#{STREAM_HTTP_URL}/messages/#{message_id}/reaction?api_key=#{STREAM_DEMO_API_KEY}"
  response = http_post(endpoint, payload)
  save_json(response, 'http_reaction.json')
end

def truncate_channel_with_message(channel_id)
  payload = {
    hard_delete: true,
    skip_push: false,
    message: {
      id: SecureRandom.uuid,
      show_in_channel: false,
      pinned: false,
      silent: false,
      text: 'Channel truncated'
    }
  }.to_json
  endpoint = "#{STREAM_HTTP_URL}/channels/messaging/#{channel_id}/truncate?api_key=#{STREAM_DEMO_API_KEY}"
  response = http_post(endpoint, payload)
  save_json(response, 'http_truncate.json')
end

def add_member_to_channel(channel_id)
  payload = {
    add_members: ['leia_organa'],
    hide_history: false
  }.to_json
  endpoint = "#{STREAM_HTTP_URL}/channels/messaging/#{channel_id}?api_key=#{STREAM_DEMO_API_KEY}"
  response = http_post(endpoint, payload)
  save_json(response, 'http_add_member.json')
end

def remove_channel(channel_id)
  endpoint = "#{STREAM_HTTP_URL}/channels/messaging/#{channel_id}?api_key=#{STREAM_DEMO_API_KEY}"
  response = http_delete(endpoint)
  save_json(response, 'http_channel_removal.json')
end

def send_attachment(channel_id)
  boundary = "----RubyMultipartPostBoundary"
  image_path = File.expand_path("#{TEST_TOOLS_FIXTURES_PATH}/yoda.jpg")
  image_basename = File.basename(image_path)
  image = File.open(image_path, 'rb')
  payload = []
  payload << "--#{boundary}\r\n"
  payload << "Content-Disposition: form-data; name=\"file\"; filename=\"#{image_basename}\"\r\n"
  payload << "Content-Type: image/jpeg\r\n\r\n"
  payload << image
  payload << "\r\n--#{boundary}--\r\n"
  headers = STREAM_HEADERS.dup
  headers['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
  endpoint = "#{STREAM_HTTP_URL}/channels/messaging/#{channel_id}/image?api_key=#{STREAM_DEMO_API_KEY}"
  response = http_post(endpoint, payload.join, headers)
  save_json(response, 'http_attachment.json')
end

def save_json(data, filename)
  File.write("#{MOCK_SERVER_FIXTURES_PATH}/#{filename}", JSON.pretty_generate(data))
  puts("✅ #{filename}")
end

def http_get(url, headers = STREAM_HEADERS)
  uri = URI(url)
  request = Net::HTTP::Get.new(uri, headers)
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  JSON.parse(response.body)
end

def http_post(url, payload, headers = STREAM_HEADERS)
  uri = URI(url)
  request = Net::HTTP::Post.new(uri, headers)
  request.body = payload
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  JSON.parse(response.body)
end

def http_delete(url, headers = STREAM_HEADERS)
  uri = URI(url)
  request = Net::HTTP::Delete.new(uri, headers)
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  JSON.parse(response.body)
end

EM.run do
  ws = Faye::WebSocket::Client.new(connect_endpoint, nil, headers: STREAM_HEADERS)

  ws.on(:message) do |event|
    case JSON.parse(event.data)['type']
    when 'health.check'
      next if @connection_id

      @connection_id = establish_websocket_connection(event.data)
      channel_id = create_channel(@connection_id)
      request_channels(@connection_id)
      send_typing_event(channel_id)
      message_id = send_message(channel_id, 'Test', 'http_message.json')
      add_reaction(message_id)
      add_member_to_channel(channel_id)
      send_attachment(channel_id)
      send_ephemeral_message(channel_id)
      send_youtube_link(channel_id)
      send_unsplash_link(channel_id)
      send_giphy_link(channel_id)
      truncate_channel_with_message(channel_id)
      remove_channel(channel_id)
    when 'typing.start'
      save_json(JSON.parse(event.data), 'ws_events.json')
    when 'message.new'
      next if @new_message

      @new_message = 1
      save_json(JSON.parse(event.data), 'ws_message.json')
    when 'reaction.new'
      save_json(JSON.parse(event.data), 'ws_reaction.json')
    when 'member.added'
      save_json(JSON.parse(event.data), 'ws_events_member.json')
    when 'channel.updated'
      json = JSON.parse(event.data)
      json['channel']['members'].each do |member|
        member['user']['privacy_settings']['typing_indicators']['enabled'] = true
        member['user']['privacy_settings']['read_receipts']['enabled'] = true
      end
      save_json(json, 'ws_events_channel.json')
    when 'channel.deleted'
      ws.close
    end
  end

  ws.on(:close) do |event|
    ws = nil
    exit 0
  end
end
