# coding: utf-8
#
# 2018-10-10, old filename was hrm.rb.
# 2018-11-24, [CREATE] /form and /push
#             [CREATE] views
# 2018-11-25, CHANGED: use USERS.map

VERSION = "0.3"

require 'sinatra'   # gem install sinatra
require 'line/bot'  # gem install line-bot-api
require 'sequel'    # gem install seqlel mysql2

helpers do
  def authenticate
    auth = Rack::Auth::Basic.new(Proc.new {}) do |username, password|
      username = 'judo' && password = 'yawara'
    end
    return auth.call(request.env)
  end
end

begin
  DB = Sequel.mysql2("bot0",
    user: ENV["BOT_USER"],
    password: ENV["BOT_PASSWORD"],
    host: 'localhost')
rescue
  STDERR.puts $!
  exit 1
end

DATA  = DB[:data]
USERS = DB[:users]
MSGS  = DB[:msgs]

BASE_URL = "https://bot.kohhoh.jp"
IMAGES = "public/images"


# FIXME: もし、USER を追加したらこれではいけなくなる。
# staff を作ればどうか？ ishii_kimura_saya でもよい。
push_to = USERS.map {|r| r[:uid]}

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
    config.channel_secret = ENV["BOT0_SECRET"]
    config.channel_token  = ENV["BOT0_TOKEN"]
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

# 2018-12-01
get '/upload' do
  @files = []
  Dir.entries(IMAGES).each do |e|
    next if e =~ /^\./
    @files.push [e, BASE_URL + "/images/" + e]
  end
  erb :upload, :layout => :layout
end

post '/upload' do
  if params[:file]
    File.open("#{IMAGES}/#{params[:file][:filename]}","wb") do |f|
      f.write params[:file][:tempfile].read
    end
  else
    return "<p>ERROR: upload failed</p>"
  end
  redirect "/upload"
end


post '/add-receiver' do
  req = params.slice "name", "uid"
  USERS.insert(name: req["name"], uid: req["uid"])

  @msg = "add receiver."
  erb :back, :layout => :layout
end

get '/add-receiver' do
  erb :add_receiver, :layout => :layout
end


post '/del-msg' do
  MSGS.where(:id => params[:id]).update(:stat => false)

  @msg = "deleted."
  erb :back, :layout => :layout
end

get '/del-msg' do
  @msgs = MSGS.where(:stat => true).all
  erb :del_msg, :layout => :layout
end

post '/add-msg' do
  req = params.slice "comment", "msg"
  MSGS.insert(comment: req["comment"], msg: req["msg"])

  @msg = "add message."
  erb :back, :layout => :layout
end

get '/add-msg' do
  erb :add_msg, :layout => :layout
end

post '/push-test' do
  req = params.slice 'user','msg'
  if req['user'].nil?
    return "<p>ERROR: receiver が選ばれていない。<a href='/push-test'>back</a></p>"
  end
  if req['msg'].nil?
    return "<p>ERROR: message が選ばれていない。<a href='/push-test'>back</a></p>"
  end
  m = MSGS.where(id: req['msg'].to_i).first[:msg]
  json = JSON.parse(m)
  req['user'].each do |u|
    uid = USERS.where(id: u).first[:uid]
    client.push_message(uid, json)
  end

  @msg="push test done."
  erb :back, :layout => :layout
end

get "/push-test" do
  # 20181126
  not_authentication = authenticate
  return not_authentication if not_authentication
  #
  @users = USERS.all
  @msgs  = MSGS.where(:stat => true).all

  erb :push_test, :layout => :layout
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

#        message = {type: 'text', text: text}
        client.reply_message(event['replyToken'], {type: 'text', text: text})

        # 受け取ったメッセージを BOT0 の USER に表示する。
        push_to.each do |dest|
          client.push_message(
            dest,
            {type: 'text', text: "BOT0 received: #{event.message['text']} from #{name}"})
        end

      end
    end
  }
  "OK"
end

# No bootstrap
get "/data" do
  # 20181126
  not_authentication = authenticate
  return not_authentication if not_authentication
  #
  ret = []
  DATA.reverse.each do |r|
    ret.push "#{r[:timestamp]} #{r[:name]} #{r[:hb]}<br>"
  end
  ret.join.to_s
end

get "/" do
  redirect "/index.html"
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
    sleep(60)
  end
end
