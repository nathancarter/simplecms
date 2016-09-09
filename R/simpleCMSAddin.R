# Some useful keyboard shortcuts for package authoring:
#
#   Build and Reload Package:  'Cmd + Shift + B'
#   Check Package:             'Cmd + Shift + E'
#   Test Package:              'Cmd + Shift + T'

# Where preferences are stored

prefsFile <- '~/.simpleCMSAddin'

# Main application function

simpleCMSAddin <- function() {

  # Shared data

  sharingChoices <- c(
    "Distribute a file to students",
    "Collect an assignment",
    "Return a graded assignment"
  )
  TESTING <- TRUE

  # User interface

  lastPreferences <- readRDS( prefsFile )
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
          HTML( '<p><label for="students">All student usernames, separated by whitespace and/or line breaks:</label></p>' ),
          tags$textarea( id='students', rows=6, cols=40, lastPreferences$students )
        ),

        # Folders column

        column(
          4,
          h3( "Folders" ),
          textInput( 'grading', 'Folder for importing files to grade:', lastPreferences$grading ),
          textInput( 'individual', 'Subfolder of each student home folder shared with you:',
                     lastPreferences$individual ),
          textInput( 'team', 'Subfolder of some student home folders shared with team:',
                     lastPreferences$team )
        ),

        # MathJax column

        column(
          4,
          h3( "MathJax" ),
          HTML( '<p><label for="mathjax">MathJax definitions to import into all worksheets:</label></p>' ),
          tags$textarea( id='mathjax', rows=6, cols=40, lastPreferences$mathjax )
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
          textInput( 'fileInput', '' )
        ),
        column(
          4,
          actionButton( 'copySafe', 'Distribute (no overwriting)' ),
          actionButton( 'copyOver', 'Distribute (overwriting)' )
        )
      ),
      hr(),
      fluidRow(
        id = "headingRow",
        column( 5, h6( 'Student folder' ) ),
        column( 2, h6( 'Contains a copy?' ) ),
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

    # Loading and saving user preferences

    preferences <- list()
    savePreferences <- function () { saveRDS( preferences, prefsFile ) }
    loadPreferences <- function () {
      if ( !file.exists( prefsFile ) ) {
        preferences <<- list(
          students = c(),
          shared = 'instructor',
          grading = 'to grade',
          teamfolder = 'team',
          mathjax = '\\def\\Z{\\mathbb{Z}}'
        )
        savePreferences()
      }
      preferences <<- readRDS( prefsFile )
    }
    setPreference <- function ( name, value ) {
      preferences[[name]] <<- value
      savePreferences()
    }
    loadPreferences()

    # Compute paths for filesystem utilities

    if ( TESTING ) {
      studentPath <- function ( student, file ) { paste0( '~', student, '/', preferences$submission, '/', file ) }
      teamPath <- function ( student, file ) { paste0( '~', student, '/', preferences$teamfolder, '/', file ) }
      instructorPath <- function ( student, file ) { paste0( preferences$grading, '/', student, '--', file ) }
      gradedPath <- function ( student, file ) { studentPath( student, paste0( 'graded--', file ) ) }
    } else {
      studentPath <- function ( student, file ) { paste0( './test-data/', student, '/', file ) }
      teamPath <- function ( student, file ) { paste0( './test-data/team1/', file ) }
      instructorPath <- function ( student, file ) { paste0( preferences$grading, '/', student, '--', file ) }
      gradedPath <- function ( student, file ) { studentPath( student, paste0( 'graded--', file ) ) }
    }

    # Splitting students list

    studentNames <- function () { strsplit( preferences$students, '\\s+' )[[1]] }
    # For the Settings tab

    observeEvent( input$students, { setPreference( 'students', input$students ) } )
    observeEvent( input$grading, { setPreference( 'grading', input$grading ) } )
    observeEvent( input$individual, { setPreference( 'individual', input$individual ) } )
    observeEvent( input$team, { setPreference( 'team', input$team ) } )
    observeEvent( input$mathjax, { setPreference( 'mathjax', input$mathjax ) } )

    observeEvent( { c( input$sharingType, input$grading ) }, {
      index <- match( input$sharingType, sharingChoices )
      if ( index == 1 )
        output$filePrompt <- renderUI( HTML( '<label class="control-label" for="fileInput">File to distribute (full path):</label>' ) )
      else if ( index == 2 )
        output$filePrompt <- renderUI( HTML( '<label class="control-label" for="fileInput">File to collect (no path):</label>' ) )
      else
        output$filePrompt <- renderUI( HTML( paste0( '<label class="control-label" for="fileInput">File to return (from ',
                                                     preferences$grading, '):</label>' ) ) )
    } )

  }

  # Launch the app in the user's default browser

  runGadget( ui, server, viewer = browserViewer() )

}
