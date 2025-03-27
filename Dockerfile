FROM node:22-bookworm

WORKDIR /src

ADD . /src
RUN npm install

CMD ["npm", "start"]