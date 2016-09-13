# Some useful keyboard shortcuts for package authoring:
#
#   Build and Reload Package:  'Cmd + Shift + B'
#   Check Package:             'Cmd + Shift + E'
#   Test Package:              'Cmd + Shift + T'

source( 'R/preferences.R' )
enableTestMode()

simpleCMSAddin <- function() {

  # Shared data

  sharingChoices <- c(
    "Distribute a file to students",
    "Collect an assignment",
    "Return a graded assignment"
  )

  # User interface

  ui <- tagList(
    useShinyjs(),
    navbarPage (
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
            textInput( 'grading', 'Folder where files await grading (absolute path):',
                       getPreference( 'grading' ) ),
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
            textInput( 'filetodistribute', 'File to distribute (full path):', getPreference( 'filetodistribute' ) ),
            textInput( 'filetocollect', 'File to collect (no path):', getPreference( 'filetocollect' ) ),
            textInput( 'filetoreturn', 'File to return (no path or username):', getPreference( 'filetoreturn' ) ),
            textOutput( 'fileStatus' )
          ),
          column(
            4,
            uiOutput( 'copySafeUI' ),
            br(),
            uiOutput( 'copyOverUI' )
          )
        ),
        fluidRow(
          column( 10 ),
          column( 2, checkboxInput( 'selectAll', 'Select/deselect all', TRUE ) )
        ),
        fluidRow(
          column( 3, h4( 'Source' ) ),
          column( 2, h4( 'Status' ) ),
          column( 3, h4( 'Destination' ) ),
          column( 2, h4( 'Status' ) ),
          column( 2, h4( 'Selection' ) )
        ),
        hr( id = 'headingRow' )
      ),

      # Monitoring tab

      tabPanel(
        "Monitoring",
        p( "Coming later" )
      )
    )
  )

  # Event handlers for the UI

  server <- function ( input, output, session ) {

    # For the Settings tab, and any other inputs that need to be preserved

    for ( key in preferencesKeys() ) {
      ( function ( k ) {
        force( k )
        observeEvent( input[[k]], { setPreference( k, input[[k]] ) } )
      } )( key )
    }

    # For updating the UI in the File Column

    lastFileUI <- -1
    updateFileUI <- function ( index ) {
      if ( index == 1 ) {
        show( 'filetodistribute' )
        hide( 'filetocollect' )
        hide( 'filetoreturn' )
        output$copySafeUI <- renderUI( actionButton( 'copySafe', 'Distribute (no overwriting)' ) )
        output$copyOverUI <- renderUI( actionButton( 'copyOver', 'Distribute (overwriting if needed)' ) )
      } else if ( index == 2 ) {
        hide( 'filetodistribute' )
        show( 'filetocollect' )
        hide( 'filetoreturn' )
        output$copySafeUI <- renderUI( actionButton( 'copySafe', 'Collect (no overwriting)' ) )
        output$copyOverUI <- renderUI( actionButton( 'copyOver', 'Collect (overwriting if needed)' ) )
      } else {
        hide( 'filetodistribute' )
        hide( 'filetocollect' )
        show( 'filetoreturn' )
        output$copySafeUI <- renderUI( actionButton( 'copySafe', 'Return (no overwriting)' ) )
        output$copyOverUI <- renderUI( actionButton( 'copyOver', 'Return (overwriting if needed)' ) )
      }
    }

    # Auxiliary routine for updating the UI in the files list

    clearFilesList <- function () removeUI( '.contentRow', multiple = TRUE )
    fillFilesList <- function ( sources, destinations ) {
      for ( i in seq_along( sources ) ) {
        sourceModified <- file.mtime( sources[i] )
        sourceStatus <- if ( is.na( sourceModified ) )
                          p( 'Does not exist' )
                        else
                          p( 'Last modified:', br(), sourceModified )
        destModified <- file.mtime( destinations[i] )
        if ( is.na( destModified ) ) {
          destStatus <- p( 'Does not exist' )
        } else if ( is.na( sourceModified ) ) {
          destStatus <- p( 'Last modified:', br(), destModified )
        } else {
          timeDelta <- difftime( sourceModified, destModified )
          if ( timeDelta > 0 ) {
            destStatus <- p( 'Older:', br(), destModified )
          } else if ( timeDelta < 0 ) {
            destStatus <- p( 'Newer:', br(), destModified )
          } else {
            sizeDelta = file.size( sources[i] ) - file.size( destinations[i] )
            destStatus <- p( 'Same time', br(), if ( sizeDelta > 0 )
                                                  'source larger'
                                                else if ( sizeDelta > 0 )
                                                  'destination larger'
                                                else
                                                  'same size' )
          }
        }
        if ( is.na( sourceModified ) ) {
          selection <- p( '(no source)' )
        } else {
          selection <- checkboxInput( paste0( 'select', i ), 'Include?', TRUE )
        }
        insertUI( '#headingRow', 'afterEnd', ui = fluidRow(
          class = 'contentRow',
          column( 3, p( sources[i] ) ),
          column( 2, sourceStatus ),
          column( 3, p( destinations[i] ) ),
          column( 2, destStatus ),
          column( 2, selection )
        ) )
      }
    }

    # Put the above three functions together

    sources <- c()
    destinations <- c()
    fullFilesUpdate <- function ( index ) {
      updateFileUI( match( input$sharingType, sharingChoices ) )
      clearFilesList()
      fillFilesList( sources, destinations )
    }

    # For handling the "Select All" checkbox

    observeEvent( input$selectAll, {
      for ( id in names(input) ) {
        if ( ( substr( id, 1, 6 ) == 'select' ) & ( id != 'selectAll' ) ) {
          updateCheckboxInput( session, id, value = input$selectAll )
        }
      }
    } )

    # Event handler that updates the files list, using the auxiliary routine defined earlier

    observeEvent( {
      c( input$sharingType, input$grading, input$filetodistribute, input$filetocollect, input$filetoreturn, input$students )
    }, {
      sources <<- c()
      destinations <<- c()
      index <- match( input$sharingType, sharingChoices )
      for ( student in studentNames() ) {
        if ( index == 1 ) {
          source <- input$filetodistribute
          destination <- studentPath( student, basename( input$filetodistribute ) )
        } else if ( index == 2 ) {
          source <- studentPath( student, input$filetocollect )
          destination <- instructorPath( student, input$filetocollect )
        } else {
          source <- instructorPath( student, input$filetoreturn )
          destination <- gradedPath( student, input$filetoreturn )
        }
        sources <<- c( sources, source )
        destinations <<- c( destinations, destination )
      }
      fullFilesUpdate()
    } )

    # Event handlers for the distribute/collect/return buttons

    transferFiles <- function ( overwrite ) {
      messages <- c()
      transfersMade <- 0
      tryCatch( {
        for ( i in seq_along( sources ) )
          if ( input[[paste0('select',i)]] )
            if ( file.copy( sources[i], destinations[i], overwrite = overwrite ) )
              transfersMade <- transfersMade + 1
      }, warning = function ( w ) { messages <<- c( messages, paste( 'WARNING:', w ) ) },
         error = function ( e ) { messages <<- c( messages, paste( 'ERROR:', e ) ) } )
      if ( length( messages ) > 0 )
        info( paste( messages, collapse = '\n' ) )
      else
        info( paste( 'Number of file transfers completed:', transfersMade ) )
      fullFilesUpdate()
    }
    observeEvent( input$copySafe, { transferFiles( FALSE ) } )
    observeEvent( input$copyOver, { transferFiles( TRUE ) } )

  }

  # Launch the app in the user's default browser

  runGadget( ui, server, viewer = dialogViewer( "Simple Course Management System", 1024, 768 ) )

}
