require 'sinatra'
require 'fileutils'
require 'stream-chat'

jwt = { expiration_timeout: {}, generation_error_timeout: {} }

post '/push/:udid/:bundle_id' do
  push_data_file = 'push_payload.json'
  File.write(push_data_file, request.body.read)
  puts `xcrun simctl push #{params['udid']} #{params['bundle_id']} #{push_data_file}`
end

post '/record_video/:udid/:test_name' do
  recordings_dir = 'recordings'
  video_base_name = "#{recordings_dir}/#{params['test_name']}"
  recordings = (0..Dir["#{recordings_dir}/*"].length + 1).to_a
  body = JSON.parse(request.body.read)
  FileUtils.mkdir_p(recordings_dir)

  video_file = ''
  if body['delete']
    recordings.reverse_each do |i|
      video_file = "#{video_base_name}_#{i}.mp4"
      break if File.exist?(video_file)
    end
  else
    recordings.each do |i|
      video_file = "#{video_base_name}_#{i}.mp4"
      break unless File.exist?(video_file)
    end
  end

  if body['stop']
    simctl_processes = `pgrep simctl`.strip.split("\n")
    simctl_processes.each { |pid| `kill -s SIGINT #{pid}` }
    File.delete(video_file) if body['delete'] && File.exist?(video_file)
  else
    puts `xcrun simctl io #{params['udid']} recordVideo --codec h264 --force #{video_file} &`
  end
end

get '/jwt/:udid' do
  time = Time.now.to_i
  if time < jwt[:generation_error_timeout][params['udid']].to_i
    halt(500, 'Intentional error')
  elsif time < jwt[:expiration_timeout][params['udid']].to_i
    'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIiLCJleHAiOjE2NjgwMTIzNTN9.UJ-LDHZFDP10sqpZU9bzPAChgersjDfqKjoi5Plg8qI'
  else
    client = StreamChat::Client.new(params[:api_key], ENV.fetch('STREAM_DEMO_APP_SECRET'))
    expiration = time + 5
    client.create_token(params[:user_name], expiration)
  end
end

post '/jwt/revoke/:udid' do
  jwt[:expiration_timeout] = install_jwt_timeout(udid: params['udid'], duration: params['duration'])
  halt(200)
end

post '/jwt/break/:udid' do
  jwt[:generation_error_timeout] = install_jwt_timeout(udid: params['udid'], duration: params['duration'])
  halt(200)
end

def install_jwt_timeout(udid:, duration:)
  { udid => Time.now.to_i + duration.to_i }
end
