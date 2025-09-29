# Register custom MIME types for KML exports
Mime::Type.register "application/vnd.google-earth.kml+xml", :kml unless Mime::Type.lookup_by_extension(:kml)
