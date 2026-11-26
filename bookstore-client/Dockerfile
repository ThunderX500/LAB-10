# Build Angular.
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --force
COPY . .
RUN npm run build -- --configuration production

# Serve the compiled application through Nginx.
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/* && apk add --no-cache gettext
COPY --from=build /app/dist/book-store/browser /usr/share/nginx/html
COPY --from=build /app/src/assets/env.template.json /usr/share/nginx/html/assets/env.template.json
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
