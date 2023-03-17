addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request));
  })
  
  async function handleRequest(request) {
    // should forward original request to the api endpoint defined in plain text binding

    // api endpoint already has the https scheme built in
    const response = await fetch(api_endpoint, request);
  
    return response;
  }