# Static copy of part of books.toscrape.com (190 pages, see README.md) for
# Crawly's end-to-end tests. Cover images are replaced by a placeholder.
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY html /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=2s --timeout=2s --retries=15 \
  CMD wget -q -O /dev/null http://127.0.0.1/index.html || exit 1
