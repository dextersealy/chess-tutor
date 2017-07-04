# Tracks

Tracks is a basic Controllers / Views framework written in Ruby and modeled after Ruby on Rails.  **ControllerBase** implements the base controller class, and **Router** provides routing capabilities.  

## ControllerBase

### Key Features

**ControllerBase** provides the following methods for descendent classes:

Method|Description
---|---
render(template_name) | Renders the file **views**/***controller_name***/***template_name***.**html.erb** into the application's main application.html.erb file.
render_content(content, content_type) | Renders content with the specified type
redirect_to(url) | Redirects to the specified URL
session | Maintains state across HTTP requests in a hash-like object
flash and flash.now | Similar to session but state is cleared after each request.
protect_from_forgery | Protects against Cross-Site Request Forgery attacks. When enabled, a valid authenticity token must accompany all data submitted to the server.

You render the CSRF token into a hidden form field as follows:
```html
<input type="hidden" name="authenticity_token"
  value="<%= form_authenticity_token %>">
```

## Router

The `Router` maps urls to actions in custom controllers.

## Rack Middleware

The following middle
Middleware|Description
---|---
ShowExceptions | Renders detailed errors messages when the controller raises an exception. The message includes the file name, line number and a snippet of the surrounding code.
Static | Serves static assets from the */assets* folder. It uses the Ruby mime-types library to identify MIME types from file extensions.
