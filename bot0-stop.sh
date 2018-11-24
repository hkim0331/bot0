#!/bin/sh
kill `ps ax | grep [b]ot0.rb | awk '{print $1}'`
