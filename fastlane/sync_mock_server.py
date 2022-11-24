import websockets
import asyncio
import requests
import urllib3
import json
import uuid
import os

stream_base_url = 'chat.stream-io-api.com'
stream_http_url = 'https://' + stream_base_url
stream_wss_url = 'wss://' + stream_base_url + '/connect'
stream_demo_api_key = '8br4watad788'
stream_demo_token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0'
stream_user_id = 'luke_skywalker'
stream_headers = { 'Authorization' : stream_demo_token, 'Stream-Auth-Type' : 'jwt' }
stream_messages_url_path = stream_http_url + '/messages'
stream_channels_url_path = stream_http_url + '/channels'
stream_messaging_url_path = stream_channels_url_path + '/messaging'
mock_server_fixtures_path = '../TestTools/StreamChatTestMockServer/Fixtures/JSONs'
test_tools_fixtures_path = '../TestTools/StreamChatTestTools/Fixtures/Images'

def connect_endpoint():
  payload = json.dumps({
    'user_id': stream_user_id,
    'user_details': {
      'id': stream_user_id,
      'name': 'Luke%20Skywalker',
      'image':'https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg',
      'birthland':'Tatooine'
    },
    'server_determines_connection_id': True
  }).replace(' ', '')
  query_params = ['api_key=' + stream_demo_api_key, 'json=' + payload]
  return stream_wss_url + '?' + '&'.join(query_params)

def request_channels(connection_id):
  payload = json.dumps({
    'filter_conditions': {
      'members': {
        '$in': [stream_user_id]
      }
    },
    'limit': 20,
    'member_limit': 30,
    'message_limit': 25,
    'watch': True
  }).replace(' ', '')
  query_params = ['api_key=' + stream_demo_api_key, 'connection_id=' + connection_id, 'payload=' + payload]
  endpoint = stream_channels_url_path + '?' + '&'.join(query_params)
  channels = requests.get(endpoint, headers=stream_headers, verify=False).json()
  return channels

def send_typing_event(type, channel_id):
  payload = json.dumps({
    'event': {
      'type': 'typing.' + type
    }
  })
  endpoint = stream_messaging_url_path + '/' + channel_id + '/event?api_key=' + stream_demo_api_key
  return requests.post(endpoint, data=payload, headers=stream_headers, verify=False).json()

def random_uuid():
  return str(uuid.uuid1())

def send_message(text, message_id, channel_id):
  payload = json.dumps({
    'message': {
      'id': message_id,
      'show_in_channel': False,
      'pinned': False,
      'silent': False,
      'text': text
    }
  })
  endpoint = stream_messaging_url_path + '/' + channel_id + '/message?api_key=' + stream_demo_api_key
  return requests.post(endpoint, data=payload, headers=stream_headers, verify=False).json()

def save_json(json_data, filename):
  with open(os.path.abspath(mock_server_fixtures_path) + '/' + filename, 'w', encoding='utf-8') as f:
    json.dump(json_data, f, sort_keys=True, ensure_ascii=False, indent=4)
    print('✅ ' + filename)

def create_channel(channel_id, connection_id):
  payload = json.dumps({
    'data': {
      'members': [stream_user_id, 'han_solo', 'count_dooku'],
      'name': 'Sync Mock Server',
    },
    'presence': True,
    'state': True,
    'watch': True,
    'messages': {
      'limit': 25
    }
  })
  query_params = ['api_key=' + stream_demo_api_key, 'connection_id=' + connection_id]
  endpoint = stream_messaging_url_path + '/' + channel_id + '/query?' + '&'.join(query_params)
  return requests.post(endpoint, data=payload, headers=stream_headers, verify=False).json()

def remove_channel(channel_id):
  endpoint = stream_messaging_url_path + '/' + channel_id + '?api_key=' + stream_demo_api_key
  return requests.delete(endpoint, headers=stream_headers, verify=False).json()

def add_reaction(message_id):
  payload = json.dumps({
    'enforce_unique': False,
    'reaction': {
      'type': 'like',
      'score': 1
    }
  })
  endpoint = stream_messages_url_path + '/' + message_id + '/reaction?api_key=' + stream_demo_api_key
  return requests.post(endpoint, data=payload, headers=stream_headers, verify=False).json()

def send_attachment(channel_id):
  image = open(os.path.abspath(test_tools_fixtures_path) + '/yoda.jpg', 'rb')
  endpoint = stream_messaging_url_path + '/' + channel_id + '/image?api_key=' + stream_demo_api_key
  return requests.post(endpoint, files={'file':image}, headers=stream_headers, verify=False).json()

def truncate_channel_with_messsage(channel_id):
  payload = json.dumps({
    'hard_delete': True,
    'skip_push': False,
    'message': {
      'id': random_uuid(),
      'show_in_channel': False,
      'pinned': False,
      'silent': False,
      'text': 'Channel truncated'
    }
  })
  endpoint = stream_messaging_url_path + '/' + channel_id + '/truncate?api_key=' + stream_demo_api_key
  return requests.post(endpoint, data=payload, headers=stream_headers, verify=False).json()

def add_member_to_channel(channel_id):
  payload = json.dumps({
    'add_members': ['leia_organa'],
    'hide_history': False
  })
  endpoint = stream_messaging_url_path + '/' + channel_id + '?api_key=' + stream_demo_api_key
  return requests.post(endpoint, data=payload, headers=stream_headers, verify=False).json()

async def chat_session():
  async with websockets.connect(connect_endpoint(), extra_headers=stream_headers) as ws:
    health_check = json.loads(await ws.recv())
    save_json(health_check, filename='ws_health_check.json')

    connection_id = health_check['connection_id']
    channel_id = random_uuid()

    channel_creation = create_channel(channel_id, connection_id)
    save_json(channel_creation, filename='http_channel_creation.json')

    channels = request_channels(connection_id)
    save_json(channels, filename='http_channels.json')

    await ws.recv() # type: notification.added_to_channel
    await ws.recv() # type: user.watching.start

    http_event = send_typing_event('start', channel_id)
    save_json(http_event, filename='http_events.json')

    ws_typing_event = json.loads(await ws.recv())
    save_json(ws_typing_event, filename='ws_events.json')

    message_id = random_uuid()
    http_message = send_message('Test', message_id=message_id, channel_id=channel_id)
    save_json(http_message, filename='http_message.json')

    ws_message = json.loads(await ws.recv())
    save_json(ws_message, filename='ws_message.json')

    http_reaction = add_reaction(message_id)
    save_json(http_reaction, filename='http_reaction.json')

    ws_reaction = json.loads(await ws.recv())
    save_json(ws_reaction, filename='ws_reaction.json')

    http_add_member = add_member_to_channel(channel_id)
    save_json(http_add_member, filename='http_add_member.json')

    ws_add_member = json.loads(await ws.recv())
    save_json(ws_add_member, filename='ws_events_member.json')

    ws_update_channel = json.loads(await ws.recv())
    save_json(ws_update_channel, filename='ws_events_channel.json')

    http_attachment = send_attachment(channel_id)
    save_json(http_attachment, filename='http_attachment.json')

    http_message_ephemeral = send_message('/giphy Test', message_id=random_uuid(), channel_id=channel_id)
    save_json(http_message_ephemeral, filename='http_message_ephemeral.json')

    youtube_link = send_message('https://youtube.com/watch?v=xOX7MsrbaPY', message_id=random_uuid(), channel_id=channel_id)
    save_json(youtube_link, filename='http_youtube_link.json')

    unsplash_link = send_message('https://unsplash.com/photos/1_2d3MRbI9c', message_id=random_uuid(), channel_id=channel_id)
    save_json(unsplash_link, filename='http_unsplash_link.json')

    channel_truncation = truncate_channel_with_messsage(channel_id)
    save_json(channel_truncation, filename='http_truncate.json')

    channel_removal = remove_channel(channel_id)
    save_json(channel_removal, filename='http_channel_removal.json')

urllib3.disable_warnings()
asyncio.run(chat_session())
