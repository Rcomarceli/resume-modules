- Ensure dependencies are installed with npm i

- How the API URL is constructed:

In the application, the API URL points to a reverse proxy (Cloudflare Workers) for our actual API Gateway. This allows us to specify an API URL in the application that *doesn't* have to change if our API gateway url changes during infrastructure redeployments. At the moment, we construct the API URL via the domain name given as an environmental variable (i.e if DOMAIN_NAME=domainname.local, the api url will be domainname.local/api)

At the moment, the application fetches the domain name on build through dotenv files (read more here: https://vitejs.dev/guide/env-and-mode.html). We initially thought to just have dev and prod build artifacts already built into the modules, but since the domain name will change from dev and prod, and to only have *1* code base for each environment, we instead choose to build out the dev and prod artifacts... in the dev and prod portion of the resume live CI/CD. This way, everything is grouped together and cleaner.

Currently, the domain name is specified in a '.env' in src with the value: VITE_DOMAIN_NAME=putYourDomainNameHere