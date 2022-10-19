require 'sinatra'
require 'fileutils'

post '/push/:udid/:bundle_id' do
  push_data_file = 'push_payload.json'
  File.open(push_data_file, 'w') { |f| f.write(request.body.read) }
  puts `xcrun simctl push #{params['udid']} #{params['bundle_id']} #{push_data_file}`
end

post '/record_video/:udid/:test_name' do
  recordings_dir = 'recordings'
  FileUtils.mkdir_p(recordings_dir)
  video_file = "#{recordings_dir}/#{params['test_name']}.mp4"

  body = JSON.parse(request.body.read)
  if body['stop']
    simctl_processes = `pgrep simctl`.strip.split("\n")
    simctl_processes.each { |pid| `kill -s SIGINT #{pid}` }
    File.delete(video_file) if body['delete'] && File.exist?(video_file)
  else
    puts `xcrun simctl io #{params['udid']} recordVideo --force #{video_file} &`
  end
end
