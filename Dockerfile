FROM node:10-stretch

WORKDIR /src

ADD . /src
RUN npm install

CMD ["npm", "start"]