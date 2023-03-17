addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request));
  })
  
  async function handleRequest(request) {
    // should forward original request to the api endpoint defined in plain text binding
    const response = await fetch('http://' + api_endpoint, request);
  
    return response;
  }