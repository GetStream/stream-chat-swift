import aiohttp
import asyncio
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
  print('Connecting to websocket...')
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

async def request_channels(session, connection_id):
  print('Requesting channel list...')
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
  async with session.get(endpoint, headers=stream_headers) as response:
    channels = await response.json()
    first_channel = channels['channels'][0]
    channels['channels'] = [first_channel]
    save_json(channels, filename='http_channels.json')

async def send_typing_event(session, ws, channel_id):
  print('Sending typing event...')
  payload = json.dumps({
    'event': {
      'type': 'typing.start'
    }
  })
  endpoint = stream_messaging_url_path + '/' + channel_id + '/event?api_key=' + stream_demo_api_key
  async with session.post(endpoint, data=payload, headers=stream_headers) as response:
    save_json(await response.json(), filename='http_events.json')

    ws_typing_event_received = False
    while not ws_typing_event_received: # multiple 'user.watching.start' events are received before the 'typing.start' event
      ws_response = (await ws.receive()).json()
      ws_typing_event_received = ws_response['type'] == 'typing.start'

    save_json(ws_response, filename='ws_events.json')

def random_uuid():
  return str(uuid.uuid1())

async def send_regular_message(session, ws, channel_id):
  message_id = await send_message(session=session, text='Test', channel_id=channel_id, filename='http_message.json')
  save_json((await ws.receive()).json(), filename='ws_message.json')
  return message_id

async def send_ephemeral_message(session, channel_id):
  await send_message(session=session, text='/giphy Test', channel_id=channel_id, filename='http_message_ephemeral.json')

async def send_youtube_link(session, channel_id):
  await send_message(session=session, text='https://youtube.com/watch?v=xOX7MsrbaPY', channel_id=channel_id, filename='http_youtube_link.json')

async def send_unsplash_link(session, channel_id):
  await send_message(session=session, text='https://unsplash.com/photos/1_2d3MRbI9c', channel_id=channel_id, filename='http_unsplash_link.json')

async def send_message(session, text, channel_id, filename):
  print('Sending message: "' + text + '"...')
  message_id = random_uuid()
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
  async with session.post(endpoint, data=payload, headers=stream_headers) as response:
    save_json(await response.json(), filename=filename)
    return message_id

def save_json(json_data, filename):
  with open(os.path.abspath(mock_server_fixtures_path) + '/' + filename, 'w', encoding='utf-8') as f:
    json.dump(json_data, f, sort_keys=True, ensure_ascii=False, indent=4)
    print('✅ ' + filename)

async def create_channel(session, connection_id):
  print('Creating channel...')
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
  channel_id = random_uuid()
  query_params = ['api_key=' + stream_demo_api_key, 'connection_id=' + connection_id]
  endpoint = stream_messaging_url_path + '/' + channel_id + '/query?' + '&'.join(query_params)
  async with session.post(endpoint, data=payload, headers=stream_headers) as response:
    save_json(await response.json(), filename='http_channel_creation.json')
    return channel_id

async def remove_channel(session, channel_id):
  print('Deleting channel...')
  endpoint = stream_messaging_url_path + '/' + channel_id + '?api_key=' + stream_demo_api_key
  async with session.delete(endpoint, headers=stream_headers) as response:
    save_json(await response.json(), filename='http_channel_removal.json')

async def add_reaction(session, ws, message_id):
  print('Adding reaction...')
  payload = json.dumps({
    'enforce_unique': False,
    'reaction': {
      'type': 'like',
      'score': 1
    }
  })
  endpoint = stream_messages_url_path + '/' + message_id + '/reaction?api_key=' + stream_demo_api_key
  async with session.post(endpoint, data=payload, headers=stream_headers) as response:
    save_json(await response.json(), filename='http_reaction.json')
    save_json((await ws.receive()).json(), filename='ws_reaction.json')

async def send_attachment(session, channel_id):
  print('Sending image attachment...')
  image = open(os.path.abspath(test_tools_fixtures_path) + '/yoda.jpg', 'rb')
  endpoint = stream_messaging_url_path + '/' + channel_id + '/image?api_key=' + stream_demo_api_key
  async with session.post(endpoint, data={'file':image}, headers=stream_headers) as response:
    save_json(await response.json(), filename='http_attachment.json')

async def truncate_channel_with_messsage(session, channel_id):
  print('Truncating channel with message...')
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
  async with session.post(endpoint, data=payload, headers=stream_headers) as response:
    save_json(await response.json(), filename='http_truncate.json')

async def add_member_to_channel(session, ws, channel_id):
  print('Adding member to channel...')
  payload = json.dumps({
    'add_members': ['leia_organa'],
    'hide_history': False
  })
  endpoint = stream_messaging_url_path + '/' + channel_id + '?api_key=' + stream_demo_api_key
  async with session.post(endpoint, data=payload, headers=stream_headers) as response:
    save_json(await response.json(), filename='http_add_member.json')
    save_json((await ws.receive()).json(), filename='ws_events_member.json')
    save_json((await ws.receive()).json(), filename='ws_events_channel.json')

async def establish_websocket_connection(ws):
  health_check = (await ws.receive()).json()
  for key in ['channel_mutes', 'mutes', 'devices']:
    health_check['me'][key] = []
  save_json(health_check, filename='ws_health_check.json')
  return health_check['connection_id']

async def chat():
  async with aiohttp.ClientSession() as session:
    async with session.ws_connect(url=connect_endpoint(), headers=stream_headers) as ws:
      connection_id = await establish_websocket_connection(ws)
      channel_id = await create_channel(session, connection_id)
      await request_channels(session, connection_id)
      await send_typing_event(session, ws, channel_id)
      message_id = await send_regular_message(session, ws, channel_id)
      await add_reaction(session, ws, message_id)
      await add_member_to_channel(session, ws, channel_id)
      await send_attachment(session, channel_id)
      await send_ephemeral_message(session, channel_id)
      await send_youtube_link(session, channel_id)
      await send_unsplash_link(session, channel_id)
      await truncate_channel_with_messsage(session, channel_id)
      await remove_channel(session, channel_id)

asyncio.run(chat())
