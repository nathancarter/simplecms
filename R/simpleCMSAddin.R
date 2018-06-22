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
        p( paste0( 'Use the drop-down to choose whether to distribute a file, collect an assignment for grading, ',
                   'or return a graded assignment.  Then fill in the filename as directed thereafter.  ' ) ),
        p( 'The filenames in the table tell you the precise file transfer actions the buttons will do.' ),
        fluidRow(
          column(
            3,
            selectInput( "sharingType", label = "Choose a file sharing action:",
                         choices = sharingChoices, selected = 1 )
          ),
          column(
            6,
            textInput( 'filetodistribute', 'File to distribute (full path):', getPreference( 'filetodistribute' ), width='600px' ),
            textInput( 'filetocollect', 'File to collect (no path):', getPreference( 'filetocollect' ), width='600px' ),
            textInput( 'filetoreturn', 'File to return (no path or username):', getPreference( 'filetoreturn' ), width='600px' ),
            textOutput( 'fileStatus' )
          ),
          column(
            3,
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
        p( paste0( 'Enter the full path to an HTML file (knitted from .Rmd) that you wish to monitor.  ',
                   'Any copy in a student or team folder will be detected.  ',
                   'Check boxes are shown for all sections where the files differ.  ',
                   'Check the boxes for the sections you want to view/compare at the bottom of this page.' ) ),
        fluidRow(
          column( 1 ),
          column( 6, textInput( 'filetomonitor', 'Master HTML file to monitor (absolute path):', getPreference( 'filetomonitor' ), width='600px' ) ),
          column( 4, uiOutput( 'fileMonitorStatus' ) ),
          column( 1 )
        ),
        fluidRow( id = 'monitorHeading', column( 3, h4( 'Copies' ) ) ),
        hr(),
        hr( id = 'monitorLine' ),
        h2( 'Selected Sections' ),
        uiOutput( 'selectedSections' )
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
        shinyjs::show( 'filetodistribute' )
        shinyjs::hide( 'filetocollect' )
        shinyjs::hide( 'filetoreturn' )
        output$copySafeUI <- renderUI( actionButton( 'copySafe', 'Distribute (no overwriting)' ) )
        output$copyOverUI <- renderUI( actionButton( 'copyOver', 'Distribute (overwriting if needed)' ) )
      } else if ( index == 2 ) {
        shinyjs::hide( 'filetodistribute' )
        shinyjs::show( 'filetocollect' )
        shinyjs::hide( 'filetoreturn' )
        output$copySafeUI <- renderUI( actionButton( 'copySafe', 'Collect (no overwriting)' ) )
        output$copyOverUI <- renderUI( actionButton( 'copyOver', 'Collect (overwriting if needed)' ) )
      } else {
        shinyjs::hide( 'filetodistribute' )
        shinyjs::hide( 'filetocollect' )
        shinyjs::show( 'filetoreturn' )
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

    # Auxiliary routine for finding any student or team files with a given basename

    findStudentAndTeamFiles <- function ( base ) {
      results <- c( input$filetomonitor )
      check <- function ( file )
        if ( is.na( match( file, results ) ) & file.exists( file ) ) results <<- c( results, file )
      for ( student in studentNames() ) {
        check( studentPath( student, base ) )
        check( teamPath( student, base ) )
      }
      results
    }

    # Auxiliary routine for extracting sections from an HTML file as character data

    getHTMLFileSections <- function ( file ) {
      xml <- htmlTreeParse( file, useInternal = TRUE )
      sections <- c()
      tryCatch( {
        sections <- xpathApply( xml, "//div[@class='section level1']" )
      }, error = function ( e ) { } )
      result <- c()
      for ( section in sections ) result <- c( result, as( section, "character" ) )
      result
    }

    # Watch file to monitor input and update its status

    observeEvent( input$filetomonitor, {

      # Clear out UI from last time
      removeUI( '.numberedHeading', multiple = TRUE )
      removeUI( '.monitoredFileRow', multiple = TRUE )

      if ( !file.exists( input$filetomonitor ) ) {
        output$fileMonitorStatus <- renderText( 'Does not exist' )
      } else {

        # List of sections next to file input box

        sectionHeadings <- c()
        tryCatch( {
          xml <- htmlTreeParse( input$filetomonitor, useInternal = TRUE )
          sectionHeadings <- xpathApply( xml, "//div[@class='section level1']/h1", xmlValue )
          status <- list( paste( length( sectionHeadings ), ' top-level headings:' ) )
          for ( i in seq_along( sectionHeadings ) ) {
            status[[length(status)+1]] <- br()
            status[[length(status)+1]] <- paste0( i, '. ', sectionHeadings[[i]] )
          }
          output$fileMonitorStatus <- renderUI( do.call( p, status ) )
        }, warning = function ( w ) {
          output$fileMonitorStatus <- renderUI( p( 'Could not read that file as XML/HTML' ) )
        }, error = function ( e ) {
          output$fileMonitorStatus <- renderUI( p( 'Could not read that file as XML/HTML' ) )
        } )

        # List of section numbers as column headers

        for ( i in seq_along( sectionHeadings ) )
          insertUI( '#monitorHeading', 'beforeEnd', column( 1, class = 'numberedHeading', h4( paste0( '§', i ) ) ) )

        # List of files as row headers, with check boxes for sections with edits

        repopulateSectionsList( list() )

      }
    } )

    # Auxiliary function for getting the list of file/section pairs the user has selected

    fileSectionPairsSelected <- function () {
      result <- list()
      re <- '^file(\\d+)section(\\d+)$'
      for ( name in sort( names( input ) ) ) {
        match <- gregexpr( re, name )
        if ( match[[1]][1] != -1 ) {
          if ( input[[name]] ) {
            fileNumber <- as.numeric( gsub( re, '\\1', regmatches( name, match )[[1]] ) )
            sectionNumber <- as.numeric( gsub( re, '\\2', regmatches( name, match )[[1]] ) )
            result[[length(result)+1]] <- c( fileNumber, sectionNumber )
          }
        }
      }
      result
    }

    # Auxiliary function for repopulating the list of selected sections

    lastHTML <- ''
    repopulateSectionsList <- function ( selected ) {
      # First, ensure the set of observed files and checkboxes is up-to-date
      removeUI( '.monitoredFileRow', multiple = TRUE )
      originalSections <- getHTMLFileSections( input$filetomonitor )
      files <- findStudentAndTeamFiles( basename( input$filetomonitor ) )
      pairEq <- function ( p1, p2 ) ( p1[1] == p2[1] ) & ( p1[2] == p2[2] )
      visibleAndSelected <- list()
      for ( j in seq_along( files ) ) {
        file <- files[j]
        thisFileSections <- getHTMLFileSections( file )
        arguments <- list( column( 3, p( file ) ) )
        for ( i in seq_along( thisFileSections ) )
          if ( i <= length( originalSections ) )
            arguments[[length(arguments)+1]] <- column(
              1,
              if ( ( j > 1 ) & ( thisFileSections[i] == originalSections[i] ) ) {
                p()
              } else {
                thisOneSelected <- !is.null( selected ) & any( sapply( selected, pairEq, c( j, i ) ) )
                if ( thisOneSelected )
                  visibleAndSelected[[length(visibleAndSelected)+1]] <- c( j, i )
                checkboxInput( paste0( 'file', j, 'section', i ), '', thisOneSelected )
              }
            )
        arguments[['class']] <- 'monitoredFileRow'
        insertUI( '#monitorLine', 'beforeBegin', do.call( fluidRow, arguments ) )
      }
      # then, based on their status, import content for the bottom of the page
      html <- paste0( "\\(", getPreference( 'mathjax' ), "\\)" )
      files <- findStudentAndTeamFiles( basename( input$filetomonitor ) )
      foundASection <- FALSE
      for ( pair in visibleAndSelected ) {
        section <- getHTMLFileSections( files[pair[1]] )[pair[2]]
        html <- paste( html, paste0( '<center><font color=red><b>From ', files[pair[1]], ':</b></font></center>' ), section )
        foundASection <- TRUE
      }
      if ( !foundASection )
        html <- paste( html, '<p>(No sections selected.)</p>' )
      if ( lastHTML != html ) {
        output$selectedSections <- renderUI( withMathJax( HTML( html ) ) )
        lastHTML <<- html
      }
    }

    # Every half second, if the set of checked checkboxes has changed, update the list shown below them
    # (and if 5 seconds have gone by, update no matter what)

    lastTime <- NULL
    timeWithNoUpdates <- 0
    observe( {
      invalidateLater( 500 )
      thisTime <- fileSectionPairsSelected()
      if ( ( timeWithNoUpdates >= 10 ) | !isTRUE( all.equal( lastTime, thisTime ) ) ) {
        lastTime <<- thisTime
        repopulateSectionsList( thisTime )
        timeWithNoUpdates <<- 0
      } else {
        timeWithNoUpdates <<- timeWithNoUpdates + 1
      }
    } )

  }

  # Launch the app in the user's default browser

  runGadget( ui, server, viewer = browserViewer() )

}
