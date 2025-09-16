[edit](https://github.com/2cld/netstack/edit/master/docs/portals/netbox/README.md) - [../portals/](../) - [../../docs/](../../)
# netbox

- https://netboxlabs.com/docs/netbox/
- yt [NetworkChuck netbox](https://www.youtube.com/watch?v=9z1_14YSaDY&t=21s)
- [https://hub.docker.com/r/linuxserver/netbox](https://hub.docker.com/r/linuxserver/netbox)
- google/aimode [create netbox](https://www.google.com/search?udm=50&aep=11&q=I%27m+trying+to+install+netbox+using+docker+compose+file.++Can+you+create+a+docker-compose.yaml+file+along+with+an+explanation+of+the+configuration+and+reference+to+online+tutorial+that+also+demonstrates+the+successful+installation%3F&mtid=mq7JaK3qLYaKptQP5afueA&mstk=AUtExfAQ1YrduLIohv9vm5cz2IdsK7foVG6NIrEzCwbnHaKfodQL5b_Ce7JZiKeZYX-ExDzAIMHnzchrmoBkZZTEGoyN1HRna5F_UXaTPggl3tKfgnYdJlI77BmBxRps8xVh5LZyADgj8yh297tLTwi836f4gZ2cOCFpVoBZiEjaXHnJA2aT-0j05rNVQ4Mb3L8A9fIzByGu4JKAqU441X70NhLlyujbMdnZNN4PBzZUmg_R21hG_7PW8_iNuNHzjC41DF0br7fmTti1knW2Sqxow_bhrjJ4cYSrTdy8BjGbXQK77ultppaFMHYWEp9Qx3tVq-Ri1SpADc37fg&csuir=1)
- [https://hub.docker.com/r/netboxcommunity/netbox/](https://hub.docker.com/r/netboxcommunity/netbox/)
- netbox community [Getting Started](https://github.com/netbox-community/netbox-docker/wiki/Getting-Started) - [netbox-docker](https://github.com/netbox-community/netbox-docker)
- netboxlabs [Install](https://netboxlabs.com/docs/netbox/installation/)
- [http://10.147.17.176:8080/](http://10.147.17.176:8080/) and [https://netbox.cat9.me/](https://netbox.cat9.me/)


```yaml
version: '3.8'

services:
  netbox:
    image: lscr.io/linuxserver/netbox:latest # Using the LinuxServer.io Netbox image
    container_name: netbox
    environment:
      # These environment variables configure Netbox itself
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      # You can set other Netbox environment variables here, for example:
      # - SUPERUSER_EMAIL=your_email@example.com
      # - SUPERUSER_PASSWORD=your_secure_password
      # - ALLOWED_HOST=your_netbox_domain.com
    volumes:
      - netbox_data:/config # Persistent storage for Netbox configuration and data
      - ./netbox_sqlite_data:/config/sqlite # Mount a directory for the SQLite database
    labels:
      - traefik.enable=true
      - traefik.http.routers.netbox.rule=Host(`your_netbox_domain.com`) # Replace with your domain
      - traefik.http.routers.netbox.entrypoints=websecure # Use HTTPS
      - traefik.http.routers.netbox.tls.certresolver=letsencrypt # If using Let's Encrypt, configure this in Traefik
      - traefik.http.services.netbox.loadbalancer.server.port=8000 # Default Netbox port
    networks:
      - traefik_net

  traefik:
    image: traefik:v3.5 # Or a later version if preferred
    container_name: traefik
    command:
      - "--api.insecure=true" # For development, expose the dashboard insecurely (change for production)
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443" # For HTTPS traffic
      # Optional: Configure Let's Encrypt for automatic TLS certificates
      # - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      # - "--certificatesresolvers.letsencrypt.acme.email=your_email@example.com"
      # - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080" # Traefik dashboard
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro" # Traefik needs access to Docker socket for container discovery
      # - traefik_letsencrypt:/letsencrypt # Volume for Let's Encrypt certificates (if enabled)
    networks:
      - traefik_net

volumes:
  netbox_data:
  # traefik_letsencrypt: # Declare this volume if using Let's Encrypt with Traefik

networks:
  traefik_net:
    external: false
```
## Netbox Service:
- image: lscr.io/linuxserver/netbox:latest: This uses the LinuxServer.io image, which simplifies Netbox deployments with pre-configured settings.
- container_name: netbox: Sets a friendly name for your Netbox container.
- environment: You can define Netbox environment variables here, such as PUID, PGID, and TZ. Remember to replace placeholder values like your_email@example.com, your_secure_password, and your_netbox_domain.com with your actual values.
## volumes:
- netbox_data:/config: This is a named volume that persists the Netbox configuration and application data outside the container, ensuring data is not lost if the container is removed or recreated.
- ./netbox_sqlite_data:/config/sqlite: This bind-mounts a local directory (netbox_sqlite_data) to the /config/sqlite directory inside the Netbox container. This is where your SQLite database file will be stored, allowing it to persist even if the container is removed and recreated, according to Stack Overflow. You'll need to create the netbox_sqlite_data directory in the same location as your docker-compose.yaml file.
- labels: These labels tell Traefik how to route requests to the Netbox service:
- traefik.enable=true: Enables Traefik routing for the Netbox container.
- traefik.http.routers.netbox.rule=Host(your_netbox_domain.com): Specifies that requests with the given hostname should be routed to Netbox. Remember to replace your_netbox_domain.com with the actual domain you'll use to access Netbox.
- traefik.http.routers.netbox.entrypoints=websecure: Forces HTTPS traffic to be used for Netbox access.
- traefik.http.routers.netbox.tls.certresolver=letsencrypt: (Optional) If you're setting up automated TLS certificate management with Let's Encrypt, this tells Traefik to use the letsencrypt resolver.
- traefik.http.services.netbox.loadbalancer.server.port=8000: Explicitly sets the port Traefik should use to communicate with the Netbox container.
- networks: - traefik_net: Connects the Netbox service to the traefik_net network, allowing Traefik to discover and route to it.
## Traefik Service:
- image: traefik:v3.5: Uses the official Traefik image.
- container_name: traefik: Sets a friendly name.
- command: These arguments configure Traefik:
- -api.insecure=true: Enables the Traefik dashboard without authentication (only for development/testing). For production, consider securing this dashboard.
- -providers.docker=true: Enables Traefik's Docker provider, allowing it to discover services by inspecting Docker container labels.
- -providers.docker.exposedbydefault=false: By default, Traefik won't expose any Docker container unless explicitly instructed via labels.
- -entrypoints.web.address=:80: Defines an HTTP entrypoint on port 80.
- -entrypoints.websecure.address=:443: Defines an HTTPS entrypoint on port 443.
- -certificatesresolvers.letsencrypt...: (Optional) These lines configure Traefik to use Let's Encrypt for automatic TLS certificate generation. Replace your_email@example.com with your email address.
- ports: Maps host ports to container ports:
- 80:80: HTTP traffic.
- 443:443: HTTPS traffic.
- 8080:8080: Traefik dashboard access.
## volumes:
- "/var/run/docker.sock:/var/run/docker.sock:ro": Grants Traefik read-only access to the Docker socket, enabling it to discover and inspect other running containers.
- traefik_letsencrypt:/letsencrypt: (Optional) Mounts a named volume to store Let's Encrypt certificates.
## networks: - traefik_net: Connects Traefik to the traefik_net network.
- Volumes and Networks:
- volumes: Defines the named volumes used by the services.
- netbox_data: Stores Netbox application data persistently.
- traefik_letsencrypt: (Optional) Used by Traefik to store Let's Encrypt certificates.
- networks: traefik_net:: Creates a dedicated Docker network called traefik_net for the services to communicate with each other securely.

Before you start
- Replace placeholders: Make sure to update your_netbox_domain.com, your_email@example.com, your_secure_password, etc., with your actual values.
- Create the SQLite directory: Create an empty directory named netbox_sqlite_data in the same directory as your docker-compose.yaml file. If you don't create it, Docker will create a mount point as a directory instead of a file, according to the Docker Community Forums.

To run this stack
- Save the content above as docker-compose.yaml in a directory.
- Create the empty netbox_sqlite_data directory within the same directory.
- Open a terminal in that directory and run: docker-compose up -d. This will build and start the containers in detached mode.
- Accessing Netbox

Once the containers are running, you should be able to access Netbox through your specified domain (your_netbox_domain.com) via HTTPS. If you've exposed the Traefik dashboard, you can access it on port 8080 (e.g., http://your_netbox_domain.com:8080).

This setup provides a robust foundation for your Netbox deployment with persistence, Traefik as a reverse proxy, and a SQLite backend. Remember to adjust the configuration to suit your specific needs and security requirements, especially regarding Traefik's dashboard access in a production environment.
