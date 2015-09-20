#!/bin/bash

RUBY_VERSION=$1

rbenv global ${RUBY_VERSION}
rbenv exec gem install bundler
rbenv rehash
rbenv global system

