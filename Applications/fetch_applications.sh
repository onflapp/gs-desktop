#!/bin/sh

set -e

cd ../../
D=`pwd`

if [ -d gs-terminal ];then
  cd ./gs-terminal
  git pull
else
  git clone https://github.com/onflapp/gs-terminal.git
fi

cd "$D"
if [ -d gs-webbrowser ];then
  cd ./gs-webbrowser
  git pull
else
  git clone https://github.com/onflapp/gs-webbrowser.git
fi

cd "$D"
if [ -d gs-textedit ];then
  cd ./gs-textedit
  git pull
else
  git clone https://github.com/onflapp/gs-textedit.git
fi

cd "$D"
if [ -d apps-gorm ];then
  cd ./apps-gorm
  git pull
else
  git clone https://github.com/gnustep/apps-gorm.git
fi

cd "$D"
#if [ -d gnumail ];then
#  cd ./gnumail
#  git pull
#else
#  git clone https://github.com/onflapp/gnumail.git
#fi

if [ -d gs-mail ];then
  cd ./gs-mail
  git pull
else
  git clone https://github.com/onflapp/gs-mail.git
fi

cd "$D"
if [ -d gs-talksoup ];then
  cd ./gs-talksoup
  git pull
else
  git clone https://github.com/onflapp/gs-talksoup.git
fi

cd "$D"
if [ -d apps-projectcenter ];then
  cd ./apps-projectcenter
  git pull
else
  git clone https://github.com/gnustep/apps-projectcenter.git
fi

cd "$D"
if [ -d simpleagenda ];then
  cd ./simpleagenda
  git pull
else
  git clone https://github.com/poroussel/simpleagenda.git
fi

cd "$D"
if [ -d apps-easydiff ];then
  cd ./apps-easydiff
  git pull
else
  git clone https://github.com/gnustep/apps-easydiff.git
fi

cd "$D"
if [ -d apps-thematic ];then
  cd ./apps-thematic
  git pull
else
  git clone https://github.com/onflapp/apps-thematic.git
fi
