# coding: utf-8
# 2018-10-10, old filename was hrm.rb.

VERSION = "0.1"

require 'sinatra'   # gem install 'sinatra'
require 'line/bot'  # gem install 'line-bot-api'
require 'sequel'

DB = Sequel.mysql2("bot0", user: 'user', password: 'password', host: 'localhost')
DATA = DB[:data]

kimura  = "U583b8f1e145218b0f4358c8d2519357d"
okamura = "Ue2bf7adb6b6e114e072d81ad42742597"
ishii   = "U7863b8ba9f247ed2233304a7e9c7a99c"

push_to = [ kimura, okamura, ishii ]

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

msg1= {
  "type": "template",
       "altText": "this is a buttons template",
       "template": {
                     "type": "buttons",
                    "actions": [
                                 {
                                   "type": "message",
                                  "label": "非常にきつい",
                                  "text": "20"
                                 },
                                 {
                                   "type": "message",
                                  "label": "きつい",
                                  "text": "15"
                                 },
                                 {
                                   "type": "message",
                                  "label": "楽である",
                                  "text": "11"
                                 },
                                 {
                                   "type": "message",
                                  "label": "非常に楽である",
                                  "text": "7"
                                 }
                               ],
                    "title": "今日の稽古の運動強度は？",
                    "text": "主観的運動強度（RPE）msg1"
                   }
}

msg11 = {
  "type": "template",
         "altText": "this is a buttons template",
         "template": {
                       "type": "buttons",
                      "actions": [
                                   {
                                     "type": "message",
                                    "label": "非常にきつい",
                                    "text": "20"
                                   },
                                   {
                                     "type": "message",
                                    "label": "きつい",
                                    "text": "15"
                                   },
                                   {
                                     "type": "message",
                                    "label": "ちょいきつい",
                                    "text": "14"
                                   },
                                   {
                                     "type": "message",
                                    "label": "普通",
                                    "text": "13"
                                   },
                                   {
                                     "type": "message",
                                    "label": "何個でも",
                                    "text": "12"
                                   },
                                   {
                                     "type": "message",
                                    "label": "楽である",
                                    "text": "11"
                                   },
                                   {
                                     "type": "message",
                                    "label": "非常に楽である",
                                    "text": "7"
                                   }
                                 ],
                      "title": "今日の稽古の運動強度は？",
                      "text": "主観的運動強度（RPE）"
                     }
}

msg12 = {
  "type": "template",
         "altText": "this is a carousel template",
         "template": {
                       "type": "carousel",
                      "actions": [],
                      "columns": [
                                   {
                                     "thumbnailImageUrl": "SPECIFY_YOUR_IMAGE_URL",
                                    "title": "タイトル",
                                    "text": "テキスト",
                                    "actions": [
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 1",
                                                  "text": "アクション 1"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 2",
                                                  "text": "アクション 2"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 3",
                                                  "text": "アクション 3"
                                                 }
                                               ]
                                   },
                                   {
                                     "thumbnailImageUrl": "SPECIFY_YOUR_IMAGE_URL",
                                    "title": "タイトル",
                                    "text": "テキスト",
                                    "actions": [
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 1",
                                                  "text": "アクション 1"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 2",
                                                  "text": "アクション 2"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 3",
                                                  "text": "アクション 3"
                                                 }
                                               ]
                                   },
                                   {
                                     "thumbnailImageUrl": "SPECIFY_YOUR_IMAGE_URL",
                                    "title": "タイトル",
                                    "text": "テキスト",
                                    "actions": [
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 1",
                                                  "text": "アクション 1"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 2",
                                                  "text": "アクション 2"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 3",
                                                  "text": "アクション 3"
                                                 }
                                               ]
                                   },
                                   {
                                     "thumbnailImageUrl": "SPECIFY_YOUR_IMAGE_URL",
                                    "title": "タイトル",
                                    "text": "テキスト",
                                    "actions": [
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 1",
                                                  "text": "アクション 1"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 2",
                                                  "text": "アクション 2"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 3",
                                                  "text": "アクション 3"
                                                 }
                                               ]
                                   },
                                   {
                                     "thumbnailImageUrl": "SPECIFY_YOUR_IMAGE_URL",
                                    "title": "タイトル",
                                    "text": "テキスト",
                                    "actions": [
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 1",
                                                  "text": "アクション 1"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 2",
                                                  "text": "アクション 2"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 3",
                                                  "text": "アクション 3"
                                                 }
                                               ]
                                   },
                                   {
                                     "thumbnailImageUrl": "SPECIFY_YOUR_IMAGE_URL",
                                    "title": "タイトル",
                                    "text": "テキスト",
                                    "actions": [
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 1",
                                                  "text": "アクション 1"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 2",
                                                  "text": "アクション 2"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 3",
                                                  "text": "アクション 3"
                                                 }
                                               ]
                                   },
                                   {
                                     "thumbnailImageUrl": "SPECIFY_YOUR_IMAGE_URL",
                                    "title": "タイトル",
                                    "text": "テキスト",
                                    "actions": [
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 1",
                                                  "text": "アクション 1"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 2",
                                                  "text": "アクション 2"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 3",
                                                  "text": "アクション 3"
                                                 }
                                               ]
                                   },
                                   {
                                     "thumbnailImageUrl": "SPECIFY_YOUR_IMAGE_URL",
                                    "title": "タイトル",
                                    "text": "テキスト",
                                    "actions": [
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 1",
                                                  "text": "アクション 1"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 2",
                                                  "text": "アクション 2"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 3",
                                                  "text": "アクション 3"
                                                 }
                                               ]
                                   },
                                   {
                                     "thumbnailImageUrl": "SPECIFY_YOUR_IMAGE_URL",
                                    "title": "タイトル",
                                    "text": "テキスト",
                                    "actions": [
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 1",
                                                  "text": "アクション 1"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 2",
                                                  "text": "アクション 2"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 3",
                                                  "text": "アクション 3"
                                                 }
                                               ]
                                   },
                                   {
                                     "thumbnailImageUrl": "SPECIFY_YOUR_IMAGE_URL",
                                    "title": "タイトル",
                                    "text": "テキスト",
                                    "actions": [
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 1",
                                                  "text": "アクション 1"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 2",
                                                  "text": "アクション 2"
                                                 },
                                                 {
                                                   "type": "message",
                                                  "label": "アクション 3",
                                                  "text": "アクション 3"
                                                 }
                                               ]
                                   }
                                 ]
                     }
}

msg2= {
  "type": "bubble",
       "hero": {
                 "type": "image",
                "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/01_1_cafe.png",
                "size": "full",
                "aspectRatio": "20:13",
                "aspectMode": "cover",
                "action": {
                            "type": "uri",
                           "uri": "http://linecorp.com/"
                          }
               },
       "body": {
                 "type": "box",
                "layout": "vertical",
                "contents": [
                              {
                                "type": "text",
                               "text": "Brown Cafe",
                               "weight": "bold",
                               "size": "xl"
                              },
                              {
                                "type": "box",
                               "layout": "baseline",
                               "margin": "md",
                               "contents": [
                                             {
                                               "type": "icon",
                                              "size": "sm",
                                              "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png"
                                             },
                                             {
                                               "type": "icon",
                                              "size": "sm",
                                              "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png"
                                             },
                                             {
                                               "type": "icon",
                                              "size": "sm",
                                              "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png"
                                             },
                                             {
                                               "type": "icon",
                                              "size": "sm",
                                              "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png"
                                             },
                                             {
                                               "type": "icon",
                                              "size": "sm",
                                              "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gray_star_28.png"
                                             },
                                             {
                                               "type": "text",
                                              "text": "4.0",
                                              "size": "sm",
                                              "color": "#999999",
                                              "margin": "md",
                                              "flex": 0
                                             }
                                           ]
                              },
                              {
                                "type": "box",
                               "layout": "vertical",
                               "margin": "lg",
                               "spacing": "sm",
                               "contents": [
                                             {
                                               "type": "box",
                                              "layout": "baseline",
                                              "spacing": "sm",
                                              "contents": [
                                                            {
                                                              "type": "text",
                                                             "text": "Place",
                                                             "color": "#aaaaaa",
                                                             "size": "sm",
                                                             "flex": 1
                                                            },
                                                            {
                                                              "type": "text",
                                                             "text": "Miraina Tower, 4-1-6 Shinjuku, Tokyo",
                                                             "wrap": true,
                                                             "color": "#666666",
                                                             "size": "sm",
                                                             "flex": 5
                                                            }
                                                          ]
                                             },
                                             {
                                               "type": "box",
                                              "layout": "baseline",
                                              "spacing": "sm",
                                              "contents": [
                                                            {
                                                              "type": "text",
                                                             "text": "Time",
                                                             "color": "#aaaaaa",
                                                             "size": "sm",
                                                             "flex": 1
                                                            },
                                                            {
                                                              "type": "text",
                                                             "text": "10:00 - 23:00",
                                                             "wrap": true,
                                                             "color": "#666666",
                                                             "size": "sm",
                                                             "flex": 5
                                                            }
                                                          ]
                                             }
                                           ]
                              }
                            ]
               },
       "footer": {
                   "type": "box",
                  "layout": "vertical",
                  "spacing": "sm",
                  "contents": [
                                {
                                  "type": "button",
                                 "style": "link",
                                 "height": "sm",
                                 "action": {
                                             "type": "uri",
                                            "label": "CALL",
                                            "uri": "https://linecorp.com"
                                           }
                                },
                                {
                                  "type": "button",
                                 "style": "link",
                                 "height": "sm",
                                 "action": {
                                             "type": "uri",
                                            "label": "WEBSITE",
                                            "uri": "https://linecorp.com"
                                           }
                                },
                                {
                                  "type": "spacer",
                                 "size": "sm"
                                }
                              ],
                  "flex": 0
                 }
}

msg3 = {
  "type": "bubble",
        "header": {
                    "type": "box",
                   "layout": "horizontal",
                   "contents": [
                                 {
                                   "type": "text",
                                  "text": "NEWS DIGEST",
                                  "weight": "bold",
                                  "color": "#aaaaaa",
                                  "size": "sm"
                                 }
                               ]
                  },
        "hero": {
                  "type": "image",
                 "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/01_4_news.png",
                 "size": "full",
                 "aspectRatio": "20:13",
                 "aspectMode": "cover",
                 "action": {
                             "type": "uri",
                            "uri": "http://linecorp.com/"
                           }
                },
        "body": {
                  "type": "box",
                 "layout": "horizontal",
                 "spacing": "md",
                 "contents": [
                               {
                                 "type": "box",
                                "layout": "vertical",
                                "flex": 1,
                                "contents": [
                                              {
                                                "type": "image",
                                               "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/02_1_news_thumbnail_1.png",
                                               "aspectMode": "cover",
                                               "aspectRatio": "4:3",
                                               "size": "sm",
                                               "gravity": "bottom"
                                              },
                                              {
                                                "type": "image",
                                               "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/02_1_news_thumbnail_2.png",
                                               "aspectMode": "cover",
                                               "aspectRatio": "4:3",
                                               "margin": "md",
                                               "size": "sm"
                                              }
                                            ]
                               },
                               {
                                 "type": "box",
                                "layout": "vertical",
                                "flex": 2,
                                "contents": [
                                              {
                                                "type": "text",
                                               "text": "7 Things to Know for Today",
                                               "gravity": "top",
                                               "size": "xs",
                                               "flex": 1
                                              },
                                              {
                                                "type": "separator"
                                              },
                                              {
                                                "type": "text",
                                               "text": "Hay fever goes wild",
                                               "gravity": "center",
                                               "size": "xs",
                                               "flex": 2
                                              },
                                              {
                                                "type": "separator"
                                              },
                                              {
                                                "type": "text",
                                               "text": "LINE Pay Begins Barcode Payment Service",
                                               "gravity": "center",
                                               "size": "xs",
                                               "flex": 2
                                              },
                                              {
                                                "type": "separator"
                                              },
                                              {
                                                "type": "text",
                                               "text": "LINE Adds LINE Wallet",
                                               "gravity": "bottom",
                                               "size": "xs",
                                               "flex": 1
                                              }
                                            ]
                               }
                             ]
                },
        "footer": {
                    "type": "box",
                   "layout": "horizontal",
                   "contents": [
                                 {
                                   "type": "button",
                                  "action": {
                                              "type": "uri",
                                             "label": "More",
                                             "uri": "https://linecorp.com"
                                            }
                                 }
                               ]
                  }
}

msg4 = {
  "size": {
            "width": 2500,
           "height": 1686
          },
        "selected": true,
        "name": "リッチメニュー 1",
        "chatBarText": "お知らせ",
        "areas": [
                   {
                     "bounds": {
                                 "x": 965,
                                "y": 317,
                                "width": 20,
                                "height": 355
                               },
                    "action": {
                                "type": "uri",
                               "uri": "http://www.judo.or.jp/p/45624"
                              }
                   }
                 ]
}

msg5={
  "type": "flex",
      "altText": "Flex Message",
      "contents": {
                    "type": "bubble",
                   "hero": {
                             "type": "image",
                            "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/01_1_cafe.png",
                            "size": "full",
                            "aspectRatio": "20:13",
                            "aspectMode": "cover",
                            "action": {
                                        "type": "uri",
                                       "label": "Line",
                                       "uri": "https://linecorp.com/"
                                      }
                           },
                   "body": {
                             "type": "box",
                            "layout": "vertical",
                            "contents": [
                                          {
                                            "type": "text",
                                           "text": "Brown Cafe",
                                           "size": "xl",
                                           "weight": "bold"
                                          },
                                          {
                                            "type": "box",
                                           "layout": "baseline",
                                           "margin": "md",
                                           "contents": [
                                                         {
                                                           "type": "icon",
                                                          "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png",
                                                          "size": "sm"
                                                         },
                                                         {
                                                           "type": "icon",
                                                          "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png",
                                                          "size": "sm"
                                                         },
                                                         {
                                                           "type": "icon",
                                                          "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png",
                                                          "size": "sm"
                                                         },
                                                         {
                                                           "type": "icon",
                                                          "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png",
                                                          "size": "sm"
                                                         },
                                                         {
                                                           "type": "icon",
                                                          "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gray_star_28.png",
                                                          "size": "sm"
                                                         },
                                                         {
                                                           "type": "text",
                                                          "text": "4.0",
                                                          "flex": 0,
                                                          "margin": "md",
                                                          "size": "sm",
                                                          "color": "#999999"
                                                         }
                                                       ]
                                          },
                                          {
                                            "type": "box",
                                           "layout": "vertical",
                                           "spacing": "sm",
                                           "margin": "lg",
                                           "contents": [
                                                         {
                                                           "type": "box",
                                                          "layout": "baseline",
                                                          "spacing": "sm",
                                                          "contents": [
                                                                        {
                                                                          "type": "text",
                                                                         "text": "Place",
                                                                         "flex": 1,
                                                                         "size": "sm",
                                                                         "color": "#AAAAAA"
                                                                        },
                                                                        {
                                                                          "type": "text",
                                                                         "text": "Miraina Tower, 4-1-6 Shinjuku, Tokyo",
                                                                         "flex": 5,
                                                                         "size": "sm",
                                                                         "color": "#666666",
                                                                         "wrap": true
                                                                        }
                                                                      ]
                                                         },
                                                         {
                                                           "type": "box",
                                                          "layout": "baseline",
                                                          "spacing": "sm",
                                                          "contents": [
                                                                        {
                                                                          "type": "text",
                                                                         "text": "Time",
                                                                         "flex": 1,
                                                                         "size": "sm",
                                                                         "color": "#AAAAAA"
                                                                        },
                                                                        {
                                                                          "type": "text",
                                                                         "text": "10:00 - 23:00",
                                                                         "flex": 5,
                                                                         "size": "sm",
                                                                         "color": "#666666",
                                                                         "wrap": true
                                                                        }
                                                                      ]
                                                         }
                                                       ]
                                          }
                                        ]
                           },
                   "footer": {
                               "type": "box",
                              "layout": "vertical",
                              "flex": 0,
                              "spacing": "sm",
                              "contents": [
                                            {
                                              "type": "button",
                                             "action": {
                                                         "type": "uri",
                                                        "label": "CALL",
                                                        "uri": "https://linecorp.com"
                                                       },
                                             "height": "sm",
                                             "style": "link"
                                            },
                                            {
                                              "type": "button",
                                             "action": {
                                                         "type": "uri",
                                                        "label": "WEBSITE",
                                                        "uri": "https://linecorp.com"
                                                       },
                                             "height": "sm",
                                             "style": "link"
                                            },
                                            {
                                              "type": "spacer",
                                             "size": "sm"
                                            }
                                          ]
                             }
                  }
}

msg6 ={
  "type": "flex",
       "altText": "Flex Message",
       "contents": {
                     "type": "bubble",
                    "header": {
                                "type": "box",
                               "layout": "horizontal",
                               "contents": [
                                             {
                                               "type": "text",
                                              "text": "JUDO NEWS",
                                              "flex": 10,
                                              "size": "md",
                                              "weight": "bold",
                                              "color": "#AAAAAA"
                                             }
                                           ]
                              },
                    "hero": {
                              "type": "image",
                             "url": "https://static.wixstatic.com/media/0fcc93_64f49d80d444475f8b9d14c5324dbdc2~mv2_d_4320_3240_s_4_2.jpg/v1/fill/w_1200,h_900,al_c,q_85,usm_0.66_1.00_0.01/DSC01627_JPG.webp",
                             "size": "full",
                             "aspectRatio": "20:13",
                             "aspectMode": "cover",
                             "action": {
                                         "type": "uri",
                                        "label": "Action",
                                        "uri": "https://linecorp.com/"
                                       }
                            },
                    "body": {
                              "type": "box",
                             "layout": "horizontal",
                             "spacing": "md",
                             "contents": [
                                           {
                                             "type": "box",
                                            "layout": "vertical",
                                            "flex": 1,
                                            "contents": [
                                                          {
                                                            "type": "image",
                                                           "url": "https://static.wixstatic.com/media/0fcc93_0a4b11f556a94063980749c3e363d707~mv2.jpg/v1/fill/w_1000,h_622,al_c,q_85/0fcc93_0a4b11f556a94063980749c3e363d707~mv2.webp",
                                                           "gravity": "bottom",
                                                           "size": "sm",
                                                           "aspectRatio": "4:3",
                                                           "aspectMode": "cover"
                                                          },
                                                          {
                                                            "type": "image",
                                                           "url": "https://static.wixstatic.com/media/0fcc93_6b7fddba14fe42eaa8ed852cad8c1047~mv2.jpg/v1/fill/w_1108,h_1477,al_c,q_85/IMG_2804_JPG.webp",
                                                           "margin": "md",
                                                           "size": "sm",
                                                           "aspectRatio": "4:3",
                                                           "aspectMode": "cover"
                                                          }
                                                        ]
                                           },
                                           {
                                             "type": "box",
                                            "layout": "vertical",
                                            "flex": 2,
                                            "contents": [
                                                          {
                                                            "type": "text",
                                                           "text": "木村先生今日も絶好調！！",
                                                           "flex": 1,
                                                           "size": "xs",
                                                           "gravity": "top"
                                                          },
                                                          {
                                                            "type": "separator",
                                                           "margin": "none"
                                                          },
                                                          {
                                                            "type": "text",
                                                           "text": "おかさやスキーの練習しろ！",
                                                           "flex": 2,
                                                           "size": "xs",
                                                           "gravity": "center"
                                                          },
                                                          {
                                                            "type": "separator"
                                                          },
                                                          {
                                                            "type": "text",
                                                           "text": "石井何してる？",
                                                           "flex": 2,
                                                           "size": "xs",
                                                           "gravity": "center"
                                                          },
                                                          {
                                                            "type": "separator"
                                                          },
                                                          {
                                                            "type": "text",
                                                           "text": "これが送れれバブルメッセージOK",
                                                           "flex": 1,
                                                           "size": "xs",
                                                           "gravity": "bottom"
                                                          }
                                                        ]
                                           }
                                         ]
                            },
                    "footer": {
                                "type": "box",
                               "layout": "horizontal",
                               "contents": [
                                             {
                                               "type": "button",
                                              "action": {
                                                          "type": "uri",
                                                         "label": "More",
                                                         "uri": "https://www.takanoriishii.com/"
                                                        }
                                             }
                                           ]
                              }
                   }
}

msg7={
  "type": "flex",
      "altText": "Flex Message",
      "contents": {
                    "type": "carousel",
                   "contents": [
                                 {
                                   "type": "bubble",
                                  "header": {
                                              "type": "box",
                                             "layout": "horizontal",
                                             "contents": [
                                                           {
                                                             "type": "text",
                                                            "text": "JUDO NEWS",
                                                            "flex": 10,
                                                            "size": "md",
                                                            "weight": "bold",
                                                            "color": "#AAAAAA"
                                                           }
                                                         ]
                                            },
                                  "hero": {
                                            "type": "image",
                                           "url": "https://static.wixstatic.com/media/0fcc93_64f49d80d444475f8b9d14c5324dbdc2~mv2_d_4320_3240_s_4_2.jpg/v1/fill/w_1200,h_900,al_c,q_85,usm_0.66_1.00_0.01/DSC01627_JPG.webp",
                                           "size": "full",
                                           "aspectRatio": "20:13",
                                           "aspectMode": "cover",
                                           "action": {
                                                       "type": "uri",
                                                      "label": "Action",
                                                      "uri": "https://linecorp.com/"
                                                     }
                                          },
                                  "body": {
                                            "type": "box",
                                           "layout": "horizontal",
                                           "spacing": "md",
                                           "contents": [
                                                         {
                                                           "type": "box",
                                                          "layout": "vertical",
                                                          "flex": 1,
                                                          "contents": [
                                                                        {
                                                                          "type": "image",
                                                                         "url": "https://static.wixstatic.com/media/0fcc93_0a4b11f556a94063980749c3e363d707~mv2.jpg/v1/fill/w_1000,h_622,al_c,q_85/0fcc93_0a4b11f556a94063980749c3e363d707~mv2.webp",
                                                                         "gravity": "bottom",
                                                                         "size": "sm",
                                                                         "aspectRatio": "4:3",
                                                                         "aspectMode": "cover"
                                                                        },
                                                                        {
                                                                          "type": "image",
                                                                         "url": "https://static.wixstatic.com/media/0fcc93_6b7fddba14fe42eaa8ed852cad8c1047~mv2.jpg/v1/fill/w_1108,h_1477,al_c,q_85/IMG_2804_JPG.webp",
                                                                         "margin": "md",
                                                                         "size": "sm",
                                                                         "aspectRatio": "4:3",
                                                                         "aspectMode": "cover"
                                                                        }
                                                                      ]
                                                         },
                                                         {
                                                           "type": "box",
                                                          "layout": "vertical",
                                                          "flex": 2,
                                                          "contents": [
                                                                        {
                                                                          "type": "text",
                                                                         "text": "木村先生今日も絶好調！！",
                                                                         "flex": 1,
                                                                         "size": "xs",
                                                                         "gravity": "top"
                                                                        },
                                                                        {
                                                                          "type": "separator",
                                                                         "margin": "none"
                                                                        },
                                                                        {
                                                                          "type": "text",
                                                                         "text": "おかさやスキーの練習しろ！",
                                                                         "flex": 2,
                                                                         "size": "xs",
                                                                         "gravity": "center"
                                                                        },
                                                                        {
                                                                          "type": "separator"
                                                                        },
                                                                        {
                                                                          "type": "text",
                                                                         "text": "石井何してる？",
                                                                         "flex": 2,
                                                                         "size": "xs",
                                                                         "gravity": "center"
                                                                        },
                                                                        {
                                                                          "type": "separator"
                                                                        },
                                                                        {
                                                                          "type": "text",
                                                                         "text": "これが送れれバブルメッセージOK",
                                                                         "flex": 1,
                                                                         "size": "xs",
                                                                         "gravity": "bottom"
                                                                        }
                                                                      ]
                                                         }
                                                       ]
                                          },
                                  "footer": {
                                              "type": "box",
                                             "layout": "horizontal",
                                             "contents": [
                                                           {
                                                             "type": "button",
                                                            "action": {
                                                                        "type": "uri",
                                                                       "label": "More",
                                                                       "uri": "https://www.takanoriishii.com/"
                                                                      }
                                                           }
                                                         ]
                                            }
                                 },
                                 {
                                   "type": "bubble",
                                  "hero": {
                                            "type": "image",
                                           "url": "https://static.wixstatic.com/media/0fcc93_c663d9a267d54364b5e77141226a8755~mv2_d_3232_2424_s_4_2.jpg/v1/fill/w_1200,h_900,al_c,q_85,usm_0.66_1.00_0.01/P1050195_JPG.webp",
                                           "size": "full",
                                           "aspectRatio": "20:13",
                                           "aspectMode": "cover",
                                           "action": {
                                                       "type": "uri",
                                                      "label": "Action",
                                                      "uri": "https://linecorp.com/"
                                                     }
                                          },
                                  "body": {
                                            "type": "box",
                                           "layout": "vertical",
                                           "spacing": "md",
                                           "contents": [
                                                         {
                                                           "type": "text",
                                                          "text": "チームミーティング",
                                                          "size": "xl",
                                                          "gravity": "center",
                                                          "weight": "bold",
                                                          "wrap": true
                                                         },
                                                         {
                                                           "type": "box",
                                                          "layout": "baseline",
                                                          "margin": "md",
                                                          "contents": [
                                                                        {
                                                                          "type": "icon",
                                                                         "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png",
                                                                         "size": "sm"
                                                                        },
                                                                        {
                                                                          "type": "icon",
                                                                         "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png",
                                                                         "size": "sm"
                                                                        },
                                                                        {
                                                                          "type": "icon",
                                                                         "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png",
                                                                         "size": "sm"
                                                                        },
                                                                        {
                                                                          "type": "icon",
                                                                         "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png",
                                                                         "size": "sm"
                                                                        },
                                                                        {
                                                                          "type": "icon",
                                                                         "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gray_star_28.png",
                                                                         "size": "sm"
                                                                        },
                                                                        {
                                                                          "type": "text",
                                                                         "text": "4.0",
                                                                         "flex": 0,
                                                                         "margin": "md",
                                                                         "size": "sm",
                                                                         "color": "#999999"
                                                                        }
                                                                      ]
                                                         },
                                                         {
                                                           "type": "box",
                                                          "layout": "vertical",
                                                          "spacing": "sm",
                                                          "margin": "lg",
                                                          "contents": [
                                                                        {
                                                                          "type": "box",
                                                                         "layout": "baseline",
                                                                         "spacing": "sm",
                                                                         "contents": [
                                                                                       {
                                                                                         "type": "text",
                                                                                        "text": "Date",
                                                                                        "flex": 1,
                                                                                        "size": "sm",
                                                                                        "color": "#AAAAAA"
                                                                                       },
                                                                                       {
                                                                                         "type": "text",
                                                                                        "text": "Monday 25, 9:00PM",
                                                                                        "flex": 4,
                                                                                        "size": "sm",
                                                                                        "color": "#666666",
                                                                                        "wrap": true
                                                                                       }
                                                                                     ]
                                                                        },
                                                                        {
                                                                          "type": "box",
                                                                         "layout": "baseline",
                                                                         "spacing": "sm",
                                                                         "contents": [
                                                                                       {
                                                                                         "type": "text",
                                                                                        "text": "Place",
                                                                                        "flex": 1,
                                                                                        "size": "sm",
                                                                                        "color": "#AAAAAA"
                                                                                       },
                                                                                       {
                                                                                         "type": "text",
                                                                                        "text": "7 Floor, No.3",
                                                                                        "flex": 4,
                                                                                        "size": "sm",
                                                                                        "color": "#666666",
                                                                                        "wrap": true
                                                                                       }
                                                                                     ]
                                                                        },
                                                                        {
                                                                          "type": "box",
                                                                         "layout": "vertical",
                                                                         "margin": "xxl",
                                                                         "contents": [
                                                                                       {
                                                                                         "type": "spacer",
                                                                                        "size": "xs"
                                                                                       },
                                                                                       {
                                                                                         "type": "image",
                                                                                        "url": "https://scdn.line-apps.com/n/channel_devcenter/img/fx/linecorp_code_withborder.png",
                                                                                        "size": "xl",
                                                                                        "aspectMode": "cover"
                                                                                       },
                                                                                       {
                                                                                         "type": "text",
                                                                                        "text": "あなたはこのQRからミーティング情報を得ることができます",
                                                                                        "margin": "xxl",
                                                                                        "size": "xs",
                                                                                        "color": "#AAAAAA",
                                                                                        "wrap": true
                                                                                       }
                                                                                     ]
                                                                        }
                                                                      ]
                                                         }
                                                       ]
                                          }
                                 }
                               ]
                  }
}

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
