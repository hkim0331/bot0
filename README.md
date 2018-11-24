# Bot0

LINE BOT の練習のつもりで作成したが、そのまま kohhoh.jp で使いまわしている。

## SYNOPSIS

## Require

* ruby 2.3.1p112 (develop: ruby 2.5.3p105)
* gem install sinatra line-bot-api sequel sqlite3 mysql2

## 0.2.0

* ADDED: get '/form', post '/push'
* CHANGED: post 'push' => get '/push'
* FIXME: sudo systemctl start bot0 では立ち上がらなくなった。user,password が原因？
* CHANGED: bot0.service で /srv/bot0/.env を読むように。読めるかな？
