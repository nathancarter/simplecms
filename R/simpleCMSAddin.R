# Hello, world!
#
# This is an example function named 'hello'
# which prints 'Hello, world!'.
#
# You can learn more about package authoring with RStudio at:
#
#   http://r-pkgs.had.co.nz/
#
# Some useful keyboard shortcuts for package authoring:
#
#   Build and Reload Package:  'Cmd + Shift + B'
#   Check Package:             'Cmd + Shift + E'
#   Test Package:              'Cmd + Shift + T'

simpleCMSAddin <- function() {
  ui <- navbarPage (
    "Simple Course Management System",
    tabPanel(
      "Settings",
      p( "Coming soon." )
    ),
    tabPanel(
      "File Sharing",
      p( "Coming soon also" )
    ),
    tabPanel(
      "Monitoring",
      p( "Coming later" )
    )
  )
  server <- function ( input, output, session ) {
  }
  runGadget( ui, server, viewer = browserViewer() )
}
