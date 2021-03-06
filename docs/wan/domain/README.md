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
    This directs DNS request for this domain to github servers for resolution.
  - Create base domain Resource Record that points to your github user.  
    ```
    Name: 2cld.github.io 
    Type: A 
    TTL: 1h 
    Data: 185.199.108.153
          185.199.109.153
          185.199.110.153
          185.199.111.153
    ```
    In this case the [2cld github netstack repo](https://github.com/2cld/netstack) is hosting the main landing page for netstack.org.  This repo has a CNAME file that will allow the github DNS servers to resolve the DNS request to a specific github user repo.
  - Create yoursubdomain (subdomian) Resource Record. For "yoursubdomain.netstack.org" you would enter the following:
    ```
    Name: yoursubdomain 
    Type: CNAME
    TTL: 1h 
    Data: 2cld.github.io.
    ```
    In this case the 2cld github user would host the "yoursubdomain" repo containing web pages for yoursubdomain.netstack.org.  This repo has a CNAME file with "yoursubdomain.netstack.org" that will allow the github DNS servers to resolve the DNS request to a specific github user repo.
2. Static Web management using CNAME on a [https://github.com/](https://github.com/) user repo.
  - Login to a github account and create a new repo [https://github.com/2cld/netstack](https://github.com/2cld/netstack)
  - Add a [README.md](https://github.com/2cld/netstack/blob/master/README.md)
  - Add file [CNAME](https://github.com/2cld/netstack/blob/master/CNAME) with the domain "netstack.org"
  - Enable [github pages custom domain](https://docs.github.com/en/github/working-with-github-pages/managing-a-custom-domain-for-your-github-pages-site)
  - Browse your domain to view static website info [https://netstack.org/](https://netstack.org/)
3. Create site reference documents
  - Add file [docs/README.md](https://github.com/2cld/netstack/blob/master/docs/README.md) to repo [https://github.com/2cld/netstack](https://github.com/2cld/netstack)
  - Repeat with additional public proceedural documentation


### Monitoring and Maintainance

- [Review your Security logs - Github](https://docs.github.com/en/github/authenticating-to-github/reviewing-your-security-log)
- [Rename and Move files on Github](https://github.blog/2013-03-15-moving-and-renaming-files-on-github/)
- [tbd]()
