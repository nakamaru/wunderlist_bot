require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'

response = HTTP.post("https://slack.com/api/rtm.start", params: {
  token: ENV['SLACK_API_TOKEN']
  })
rc = JSON.parse(response.body)

url = rc['url']

EM.run do
  ws = Faye::WebSocket::Client.new(url)

  ws.on :open do
    p [:open]
  end

  ws.on :message do |event|
    data = JSON.parse(event.data)
    user_name = nil

    if data['attachments'] && data['attachments'][0]['pretext'].match(/commented on/) && data['attachments'][0]['fallback'].match(/@\w{1,10}/)
      url = data['attachments'][0]['pretext'].match(/https:\/\/wunderlist.com\/#\/tasks\/\d*/)
      t = data['attachments'][0]['pretext'].match(/\|.*/).to_s
      task_name = t.delete!("|").delete!(">")
      user = data['attachments'][0]['fallback'].match(/@\w{1,10}\.?\w{1,10}/).to_s
      message = data['attachments'][0]['text'].delete!("#{user}")

      if user == "@nakamaru" || user == '@n' || user == '@maru'
        user_name = '@nakamaru'
      elsif user == '@murata' || user == '@m' || user == '@muratayusuke'
        user_name = '@muratayusuke'
      elsif user == '@fujiwara' || user == '@f' || user == '@santa0127'
        user_name = '@santa0127'
      elsif user == '@sato' || user == '@s' || user == '@shohei' || user == '@shohei.sato'
        user_name = '@shohei.sato'
      end

      if user_name
        ws.send({
          type: 'message',
          text: "タスク名：#{task_name}\n" + "#{user_name} " + "#{message}\n " + "#{url}",
          channel: "C5GGC1E67"
          }.to_json)
      end
    end
  end

  ws.on :close do
    p [:close, ws.url]
    ws = nil
    EM.stop
  end
end