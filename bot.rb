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
    p 'comments data'
    p [:comment, data]

    if data['attachments']
      if data['attachments'][0]['pretext'].match(/commented on/) && data['attachments'][0]['fallback'].match(/@nakamaru/)
        url = data['attachments'][0]['pretext'].match(/https:\/\/wunderlist.com\/#\/tasks\/\d*/)
        t = data['attachments'][0]['pretext'].match(/\|.*/).to_s
        task_name = t.delete!("|").delete!(">")
        message = data['attachments'][0]['text'].delete!("@nakamaru")
        user = data['attachments'][0]['fallback'].match(/@nakamaru/)[0]
        
        ws.send({
          type: 'message',
          text: "タスク名：#{task_name}\n" + "#{user} " + "#{message}\n " + "#{url}",
          channel: "C5FKTB7J5"
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