# coding: utf-8
# 2018-10-10, old filename was hrm.rb.
# [CREATE] /form and /push

VERSION = "0.2.0"

require 'sinatra'   # gem install 'sinatra'
require 'line/bot'  # gem install 'line-bot-api'
require 'sequel'

DB = Sequel.mysql2("bot0",
  user: ENV["BOT_USER"],
  password: ENV["BOT_PASSWORD"],
  host: 'localhost')
DATA  = DB[:data]
USERS = DB[:users]
MSGS  = DB[:msgs]

# better from DB[:users]
kimura  = "U583b8f1e145218b0f4358c8d2519357d"
okamura = "Ue2bf7adb6b6e114e072d81ad42742597"
ishii   = "U7863b8ba9f247ed2233304a7e9c7a99c"

push_to = [ kimura, okamura, ishii ]

class Hash
  def slice(*whitelist)
    whitelist.inject({}){|result,key| result.merge(key=> self[key])}
  end
end

def ask_avg(name)
  DB["select avg(hb) from data where name = ?", name].first[:"avg(hb)"].round
end

def ask_std(name)
  DB["select std(hb) from data where name = ?", name].first[:"std(hb)"].round
end

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = "dcca2a5a3963facdae41a4a2e20555e8"
    config.channel_token = "rMS8Kf7UNnc8BvuzZ2aIPqUSDFtmvSUYOrkAeRl15GGQ5Jtm/XWq16/YpA1LIqZzOjbXEbwoV1PsB/JJ3QFmZwgvB7mU/SKsrg0wDF7BZD3eONkpkZ2GK04a7WLLwvWJb2zxndJ7/5jxwPCkOcVpRQdB04t89/1O/w1cDnyilFU="
  }
end

def displayName(user_id)
  response = client.get_profile(user_id)
  contact = JSON.parse(response.body)
  contact['displayName']
end

# text: 私の心拍数は71 bpmです。
def int_value(text)
  /\d+/.match(text)[0]
end

def db_save(name, value)
  DATA.insert(name: name, hb: value, timestamp: Time.now)
end

get '/push' do
    req = params.slice "id"
    id = req["id"].to_i
    m = MSGS.where(id: id).first[:msg]
    json = JSON.parse(m)
    if json.nil?
      "<p>json error</p>"
    else
      USERS.each do |user|
        client.push_message(user[:uid], json)
      end
      "<p>sent. <a href='/form'>back</a></p>"
    end
end

get '/form' do
  ret="<form action='/push'><h2>Select message</h2>"
  MSGS.each do |m|
    ret << "<p><input type='radio' name='id' value='#{m[:id]}'>
    #{m[:timestamp]}
    #{m[:comment]}:
    #{m[:msg][0..50]}</p>"
  end
  ret << "<input type='submit' value='push'></form>"
end

post '/callback' do
  body = request.body.read
  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        name = displayName(event['source']['userId'])
        File.open("/srv/bot0/bot0.log","a") do |fp|
          fp.puts "#{name} #{event['source']['userId']}"
        end
        value= int_value(event.message['text'])

        # データベースを更新
        db_save(name, value.to_i) unless value.empty?

        # メッセージを LINE に返す
        avg = ask_avg(name)
        std = ask_std(name)

        text = "平均値は #{avg} です。
#{avg+std}~#{avg+2*std} は注意です。
#{avg+2*std}~ は要注意です。
休養を検討しましょう。"
        message = {
          type: 'text',
          text: text
        }
        client.reply_message(event['replyToken'], message)

        # push test
        push_to.each do |dest|
          client.push_message(dest, {type: 'text',
                                     text: "BOT0 got #{event.message['text']} from #{name}"})
        end
        # push test end

        # web の画面
        File.open("public/index.html","a") do |fp|
          fp.puts "<p>#{Time.now} #{name} #{value}</p>"
        end
      end
    end
  }
  "OK"
end

get "/" do
  ret = []
  DATA.reverse.each do |r|
    ret.push "<p>#{r[:timestamp]} #{r[:name]} #{r[:hb]}</p>"
  end
  ret.join.to_s
end

Thread.new do
  while (true)
    now = Time.now.strftime("%H%M")
    if now =~ /0800/
      push_to.each do |user|
        client.push_message(user, {type: 'text',
                                   text: "８時だよ。博論頑張れ。さーやはスキー頑張れ"})
      end
    end

    ## ng
    # if now =~ /0$/
    #   push_to.each do |user|
    #     client.push_message(user, msg1)
    #   end
    # end
    #
    # ng
    # push_to.each do |user|
    #   client.push_message(user, msg2)
    # end
    # puts "sent #{now}"
    #
    ## goes well.
    #push_to.each do |user|
    #  client.push_message(user, msg7)
    #end
    #
    sleep(60)
  end
end
