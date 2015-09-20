#!/bin/bash

VERSION=$1
rbenv install ${VERSION}
rbenv rehash
