# Use the official nginx image as base
FROM nginx:alpine

# Copy the webapp files to nginx's default serving directory
COPY webapp /usr/share/nginx/html/

# Expose port 8080 (Cloud Run requirement)
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"] 