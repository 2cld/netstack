
# Tunnel Everything with a SOCKS proxy
1. Log in to the remote machine using the following command:
```bash
ssh -D 8080 remote-host
```
2. Now go to your browser's proxy settings, and configure it to use a SOCKS proxy with host name 127.0.0.1 and port 8080 (or whatever port you passed to the -D option). Now all pages you load in your web browser will be tunnelled through the SSH connection. You should now be able to access the private web page in the same way you would from the remote host.
3. Once you are done, set your browser's proxy settings back to normal.

 ## NOTE:
 All other traffic in the web browser will also be going through the SSH connection. On the upside, you can access the remote servers with their real host names, and can easily access multiple private sites.

# Tunnel a single port.
The alternative method is to use SSH to forward a single port:
1. setup ssh tunnel
```bash
ssh -L 8080:server-hostname:80 remote-host
```
2. Point your web browser at http://localhost:8080/, you should see the contents of http://server-hostname/ as it would appear from the remote host.

The benefit of this method is that it leaves the rest of the browser traffic alone. The downside is that some links might not work if the remote site uses absolute URL references. If the site mostly uses relative URL references, then this method should be sufficient.
For both of these solutions, there is nothing special about the port 8080. You can use any free local port number you want, as long as you remember to use the same one in the ssh invocation and in the web browser.
