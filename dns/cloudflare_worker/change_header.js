addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request));
  })
  
  async function handleRequest(request) {
    let path = new URL(request.url).pathname;
    const response = await fetch('http://' + website_endpoint + path, request);
  
    return response;
  }