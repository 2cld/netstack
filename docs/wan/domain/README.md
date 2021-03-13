[documents index](../../)
# netstack wide area network (wan) domain setup

Current default netstack proceedure for public domain interface setup.

1. Domain name management using [https://domains.google/](https://domains.google/)
  - Purchace your domain name using a google user accout you will manage this domain with.
  - Go to [https://domains.google.com/registrar/netstack.org/dns](https://domains.google.com/registrar/netstack.org/dns)
  - Use the Google Domains name servers
  - Create @ Resource Record pointing to [github page servers](https://docs.github.com/en/github/working-with-github-pages/managing-a-custom-domain-for-your-github-pages-site)
    ```
    Name: @ 
    Type: A 
    TTL: 1h 
    Data: 185.199.108.153
          185.199.109.153
          185.199.110.153
          185.199.111.153
    ```
  - Create base domain Resource Record that points to your github user.  In this case the [2cld github netstack repo](https://github.com/2cld/netstack) is hosting the main landing page for netstack.org.
    ```
    Name: 2cld.github.io 
    Type: A 
    TTL: 1h 
    Data: 185.199.108.153
          185.199.109.153
          185.199.110.153
          185.199.111.153
    ```
  - Create yoursubdomain (subdomian) Resource Record. For "yoursubdomain.netstack.org" you would enter the following:
    ```
    Name: yoursubdomain 
    Type: CNAME
    TTL: 1h 
    Data: netstack.org.
    ```
2. Static Web management using [https://github.com/](https://github.com/)
  - Login to a github account and create a new repo [https://github.com/2cld/netstack](https://github.com/2cld/netstack)
  - Add a [README.md](https://github.com/2cld/netstack/blob/master/README.md)
  - Add file [CNAME](https://github.com/2cld/netstack/blob/master/CNAME) with the domain "netstack.org"
  - Enable [github pages custom domain](https://docs.github.com/en/github/working-with-github-pages/managing-a-custom-domain-for-your-github-pages-site)
  - Browse your domain to view static website info [https://netstack.org/](https://netstack.org/)
3. Create site reference documents
  - Add file [docs/README.md](https://github.com/2cld/netstack/blob/master/docs/README.md) to repo [https://github.com/2cld/netstack](https://github.com/2cld/netstack)
  - Repeat with additional public proceedural documentation
