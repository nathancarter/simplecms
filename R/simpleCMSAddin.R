# Some useful keyboard shortcuts for package authoring:
#
#   Build and Reload Package:  'Cmd + Shift + B'
#   Check Package:             'Cmd + Shift + E'
#   Test Package:              'Cmd + Shift + T'

source( 'R/preferences.R' )

simpleCMSAddin <- function() {

  # Shared data

  sharingChoices <- c(
    "Distribute a file to students",
    "Collect an assignment",
    "Return a graded assignment"
  )

  # User interface

  ui <- navbarPage (
    "Simple Course Management System",

    # Settings tab

    tabPanel(
      "Settings",
      p( paste0( 'Fill in these blanks the first time you set up this tool for your course.  ',
                 'Each change you make will be saved into a hidden preferences file in your home folder (', prefsFile, ').' ) ),
      p( 'You can change settings if you need to, right here.  Changes are automatically saved immediately.' ),
      fluidRow(

        # Students column

        column(
          4,
          h3( "Students" ),
          textAreaInput( 'students', 'All student usernames, separated by whitespace and/or line breaks:', getPreference( 'students' ) )
        ),

        # Folders column

        column(
          4,
          h3( "Folders" ),
          textInput( 'grading', 'Folder for importing files to grade:', getPreference( 'grading' ) ),
          textInput( 'individual', 'Subfolder of each student home folder shared with you:',
                     getPreference( 'individual' ) ),
          textInput( 'teamfolder', 'Subfolder of some student home folders shared with team:',
                     getPreference( 'teamfolder' ) )
        ),

        # MathJax column

        column(
          4,
          h3( "MathJax" ),
          textAreaInput( 'mathjax', 'MathJax definitions to import into all worksheets:', getPreference( 'mathjax' ) )
        )
      )
    ),

    # File Sharing tab

    tabPanel(
      "File Sharing",
      fluidRow(
        column(
          4,
          selectInput( "sharingType", label = "Choose a file sharing action:",
                       choices = sharingChoices, selected = 1 )
        ),
        column(
          4,
          uiOutput( 'filePrompt' ),
          textInput( 'fileInput', '', getPreference( 'fileInput' ) ),
          textOutput( 'fileStatus' )
        ),
        column(
          4,
          uiOutput( 'copySafeUI' ),
          br(),
          uiOutput( 'copyOverUI' )
        )
      ),
      hr(),
      fluidRow(
        id = "headingRow",
        column( 5, h6( 'Student folder' ) ),
        column( 2, h6( 'File exists?' ) ),
        column( 3, h6( 'Last modified' ) ),
        column( 2, h6( 'Action' ) )
      )
    ),

    # Monitoring tab

    tabPanel(
      "Monitoring",
      p( "Coming later" )
    )
  )

  # Event handlers for the UI

  server <- function ( input, output, session ) {
    # For the Settings tab

    for ( key in preferencesKeys() ) {
      ( function ( k ) {
        force( k )
        observeEvent( input[[k]], { setPreference( k, input[[k]] ) } )
      } )( key )
    }

    observeEvent( {
      c( input$sharingType, input$grading, input$fileInput, input$students )
    }, {
      index <- match( input$sharingType, sharingChoices )
      if ( index == 1 ) {
        output$filePrompt <- renderUI( HTML( '<label class="control-label" for="fileInput">File to distribute (full path):</label>' ) )
        output$copySafeUI <- renderUI( actionButton( 'copySafe', 'Distribute (no overwriting)' ) )
        output$copyOverUI <- renderUI( actionButton( 'copyOver', 'Distribute (with overwriting)' ) )
        removeUI( '.contentRow', multiple = TRUE )
        for ( student in studentNames() ) {
          destination <- studentPath( student, basename( input$fileInput ) )
          origExists <- file.exists( input$fileInput )
          destExists <- file.exists( destination )
          output$fileStatus <- renderText( if ( origExists ) paste( 'Last modified:', file.mtime( input$fileInput ) ) else 'No such file' )
          insertUI( '#headingRow', 'afterEnd', ui = fluidRow( class = 'contentRow',
            column( 5, p( destination ) ),
            column( 2, p( destExists ) ),
            column( 3, p( file.mtime( destination ) ) ),
            column( 2, if ( destExists & origExists )
                         actionButton( paste0( 'sendOver_', student ), 'Overwrite' )
                       else if ( origExists )
                         actionButton( paste0( 'sendSafe_', student ), 'Send file' )
                       else
                         p() )
          ) )
        }
      } else if ( index == 2 ) {
        output$filePrompt <- renderUI( HTML( '<label class="control-label" for="fileInput">File to collect (no path):</label>' ) )
        output$copySafeUI <- renderUI( actionButton( 'copySafe', 'Collect (no overwriting)' ) )
        output$copyOverUI <- renderUI( actionButton( 'copyOver', 'Collect (with overwriting)' ) )
      } else {
        output$filePrompt <- renderUI( HTML( paste0( '<label class="control-label" for="fileInput">File to return (from ',
                                                     getPreference( 'grading' ), '):</label>' ) ) )
        output$copySafeUI <- renderUI( actionButton( 'copySafe', 'Return (no overwriting)' ) )
        output$copyOverUI <- renderUI( actionButton( 'copyOver', 'Return (with overwriting)' ) )
      }
    } )

  }

  # Launch the app in the user's default browser

  runGadget( ui, server, viewer = browserViewer() )

}
