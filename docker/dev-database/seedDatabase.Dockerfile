FROM node:18-alpine

WORKDIR /db-setup

COPY ./package-lock.json* ./
COPY ./package.json ./

RUN npm install