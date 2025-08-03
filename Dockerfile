# Use the official nginx image as base
FROM nginx:alpine

# Copy the webapp files to nginx's default serving directory
COPY webapp/public /usr/share/nginx/html/

# Copy a custom nginx configuration (optional, for better performance)
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 8080 (Cloud Run requirement)
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"] 