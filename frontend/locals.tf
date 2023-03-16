locals {
  # Maps file extensions to mime types
  # Need to add more if needed
  mime_type_mappings = {
    html = "text/html",
    js   = "text/javascript",
    css  = "text/css"
  }

  build_folder = "dist"
}