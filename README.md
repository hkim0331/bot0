# Bot0

LINE BOT の練習のつもりで作成したが、そのまま使いまわしている。

## SYNOPSIS

## Require

* ruby 2.3.1p112 (develop: ruby 2.5.3p105)
* gem install sinatra line-bot-api sequel mysql2

## 0.2.*

* [0.2.7] message を登録解除できる。
* alter table msgs add column stat bool default true
* CHANGED: db/ の sql スクリプトを git 入り。
* ADDED: get '/form', post '/push'
* CHANGED: post 'push' => get '/push'
* FIXME: sudo systemctl start bot0 では立ち上がらなくなった。user,password が原因？
* CHANGED: 0.2.1, bot0.service で /srv/bot0/.env を読むように。読めるかな？
  export BOT_USER="user" ではダメで、
  BOT_USER="user"だといいの？
* CREATE: 0.2.4, views.
* FIXME: エラーメッセージの表示方法。
* Bootstrap.


---
hiroshi . kimura . 0331 @ gmail . com

