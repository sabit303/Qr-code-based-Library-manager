FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci 

COPY . .

#RUN npm run build
RUN npm install -g nodemon tsx

EXPOSE 3000

CMD ["nodemon", "--watch", "src","--ext","ts","--exec","tsx", "src/server.ts","--legacy-watch"]
