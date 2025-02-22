# NGXALL

[![Build and Push](https://github.com/amonlibanio/ngxall/actions/workflows/docker.yml/badge.svg)](https://github.com/amonlibanio/ngxall/actions/workflows/docker.yml)
[![GitHub source](https://img.shields.io/badge/Github-source-informational?logo=github)](https://github.com/amonlibanio/ngxall/)
[![GitHub license](https://img.shields.io/github/license/amonlibanio/ngxall.svg)](https://github.com/amonlibanio/ngxall?tab=MIT-1-ov-file)
[![GitHub release](https://img.shields.io/github/release/amonlibanio/ngxall.svg)](https://github.com/amonlibanio/ngxall/releases/)


This project provides an enhanced version of Nginx, compiled from the source on Alpine Linux and integrated with several additional modules to extend its functionalities.

The project encompasses the standard Nginx modules as well as supplementary features that improve caching, optimization, security, and monitoring.

## Included Features

- **Standard Modules:**
  - Provides essential functions including HTTP request handling, mail support, and foundational services necessary for robust server operations.
- **Additional HTTP Modules:**
  - Supports execution of custom scripts to extend server functionalities.
  - Enhances performance by optimizing page load times and resource management.
  - Implements advanced compression techniques to reduce response sizes and improve network efficiency.
  - Enables programmatic cache invalidation to guarantee the delivery of updated content.
  - Allows customization of HTTP headers to meet specific security and communication requirements.
  - Improves directory listings with enhanced formatting and navigation options.
  - Facilitates dynamic modification of response content for real-time adjustments.
  - Integrates visitor geolocation to provide location-based analytics and content customization.
  - Offers capabilities for real-time media streaming to support live content delivery.
- **Monitoring:**
  - Incorporates comprehensive performance tracking using Open Telemetry for monitoring server health, request latency, and resource usage.

## Versions Utilized

- Alpine Linux: 3.21
- Nginx: 1.27.4

## Detailed Modules and Their Functions

### Secure Communication (Module: ngx_http_ssl_module)
Implements SSL/TLS encryption for secure connections, ensuring the protection of data transmissions.
Usage:
```nginx
server {
    listen 443 ssl;
    ssl_certificate /path/to/cert;
    ssl_certificate_key /path/to/key;
}
```

### Real IP Identification (Module: ngx_http_realip_module)
Retrieves the actual IP address of the client, facilitating accurate logging and improved access control.
Usage:
```nginx
http {
    real_ip_header X-Forwarded-For;
    set_real_ip_from 192.168.0.0/16;
}
```

### Response Addition (Module: ngx_http_addition_module)
Inserts supplementary information into HTTP responses, enabling server-specific customizations.
Usage:
```nginx
location / {
    addition "Powered by NGXALL";
}
```

### WebDAV Support (Module: ngx_http_dav_module)
Enables HTTP methods for file management, allowing both read and write operations via WebDAV.
Usage:
```nginx
location /files/ {
    dav_methods PUT DELETE MKCOL COPY MOVE;
    create_full_put_path on;
}
```

### Media Streaming (Module: ngx_http_flv_module)
Provides the necessary capabilities for video and audio streaming, ideal for streaming applications.
Usage:
```nginx
location /video/ {
    flv;
}
```

### Decompression and Serving Pre-compressed Content (Modules: ngx_http_gunzip_module & ngx_http_gzip_static_module)
Automatically decompresses compressed content and serves pre-compressed files to improve performance.
Usage:
```nginx
location /static/ {
    gzip_static on;
}
```

### Customized Directory Listings (Module: ngx_fancyindex)
Replaces the conventional directory listing with an enhanced and organized display.
Usage:
```nginx
location /files/ {
    fancyindex on;
}
```

### Real-time Content Substitution (Module: ngx_http_substitutions_filter_module)
Dynamically modifies HTTP response content to allow real-time customization.
Usage:
```nginx
location / {
    sub_filter 'original' 'new';
    sub_filter_once off;
}
```

### Visitor Geolocation (Module: ngx_http_geoip2_module)
Determines the geographical location of users based on their IP addresses, facilitating geographical analysis.
Usage:
```nginx
http {
    geoip2 /etc/nginx/GeoLite2-City.mmdb {
        $geoip2_data city names en;
    }
}
```
Note: If a MAXMIND_LICENSE_KEY is provided (see .env.example), the system will automatically download and periodically update the MMDB file.

### Live Streaming (Module: nginx-rtmp-module)
Enables live media streaming, supporting real-time broadcasts.
Usage:
```nginx
rtmp {
    server {
        listen 1935;
        application live {
            live on;
        }
    }
}
```

### Embedded Script Execution (Module: lua-nginx-module)
Facilitates the execution of lightweight scripts, permitting advanced customizations and functionalities.
Usage:
```nginx
location /lua {
    content_by_lua 'ngx.say("Hello World")';
}
```

### Monitoring and Tracing (Module: nginx-module-otel)
Provides resources to monitor and trace server performance, assisting in diagnosis and metrics analysis.
Usage:
```nginx
load_module modules/ngx_otel_module.so;
http {
    otel_trace on;
}
```

## Usage Examples

### Building the Docker Image

From the project root directory, execute:

```bash
docker build -t ngxall .
```

### Running the Container

To run the container with a local directory for static files:

```bash
docker run -v /path/to/html:/var/www/html -p 8080:80 ngxall
```

For a custom configuration, use the command below:

```bash
docker run -v /path/to/html:/var/www/html -v /path/to/conf:/etc/nginx/conf.d -p 8080:80 ngxall
```

## Dynamic Distribution and Configuration

The image is available for download directly from Docker Hub:

```bash
docker pull amonlibanio/ngxall
```

It is also possible to define environment variables for use within the nginx.conf file or any configuration files located in conf.d/*.conf dynamically. For example:

```bash
docker run -e SERVER_NAME=example.com -v /path/to/conf:/etc/nginx/conf.d -p 8080:80 amonlibanio/ngxall
```

The entrypoint executes the envsubst tool to perform environment variable substitution at runtime in both nginx.conf and files located in conf.d/*.conf.

## Container Customization

- The directory **/var/www/html** serves as the root for static files.
- The directory **/etc/nginx/conf.d** holds the Nginx configuration files.
- To modify the modules or compilation settings, adjust the `Dockerfile` and review the relevant compilation options accordingly.

## Project Advantages

- Versatility: Integrates additional modules not included in the standard version of Nginx.
- Performance: Custom-compiled to deliver optimal performance and scalability.
- Efficiency: Utilizes Alpine Linux to provide a lightweight image with minimal dependencies.
- Extensibility: Supports customizations through the inclusion of additional modules and specific configuration adjustments.

## Technical Notes and Suggestions for Improvement

- **Dynamic Configuration:**  
  The container utilizes an entrypoint to run envsubst, which performs runtime substitution of environment variables in both the nginx.conf file and files within conf.d/*.conf.  
  Example:
  ```nginx
  server {
      listen       80;
      server_name  ${SERVER_NAME};
      # additional configurations...
  }
  ```
  
- **Configuration Customization:**  
  To dynamically adjust Nginx configurations, specify environment variables when starting the container.  
  Example:
  ```bash
  docker run -e SERVER_NAME=example.com -v /path/to/conf:/etc/nginx/conf.d -p 8080:80 amonlibanio/ngxall
  ```

## License

This project is open source. Please refer to the LICENSE file for further details.
