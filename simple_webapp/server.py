from http.server import HTTPServer, BaseHTTPRequestHandler

# Create webapp object
class webapp( BaseHTTPRequestHandler ):
 
  # Define GET method
  def do_GET( serve ):
    # Define index page
    if serve.path == "/":
      serve.path = "/index.html"
    # Define responses for existent/nonexistent files
    try:
      content = open( serve.path[1:] ).read()
      serve.send_response( 200 )
    except:
      content = "404 Not Found"
      serve.send_response( 404 )
        
    # Need to end headers before writing content
    serve.end_headers()
    # Write content
    serve.wfile.write( bytes( content, "utf-8" ) )

# Create webserver to serve webapp object
webserver = HTTPServer( ("", 8080 ), webapp )
webserver.serve_forever()
