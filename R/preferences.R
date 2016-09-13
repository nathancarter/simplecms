
#------ Loading and saving user preferences ------#

# Where preferences are stored

prefsFile <- '~/.simpleCMSAddin'

# Functions for reading/writing preferences

getPreference <- setPreference <- preferencesKeys <- NULL
local( {

  # Internal API

  preferences <- list()
  savePreferences <- function () saveRDS( preferences, prefsFile )
  loadPreferences <- function () {
    if ( !file.exists( prefsFile ) ) {
      preferences <<- list(
        students = c(),
        individual = 'invididual',
        grading = 'to grade',
        teamfolder = 'team',
        mathjax = '\\def\\Z{\\mathbb{Z}}',
        filetodistribute = '',
        filetocollect = '',
        filetoreturn = ''
      )
      print( 'Created new preferences file!' )
      print( preferences )
      savePreferences()
    }
    preferences <<- readRDS( prefsFile )
    print( preferences )
  }
  loadPreferences()

  # External API

  getPreference <<- function ( name ) preferences[[name]]
  setPreference <<- function ( name, value ) {
    preferences[[name]] <<- value
    savePreferences()
  }
  preferencesKeys <<- function () names(preferences)

} )

# File-related functions built on the basic preferences

# When debugging, it's useful to use some test data stored in this repository.
# To do so, use the following function to turn testing mode on.
# This makes all the file-related functions operate on the test data and folders.

enableTestMode <- disableTestMode <- testModeOn <- NULL
local( {

  testMode <- FALSE

  enableTestMode <<- function () testMode <<- TRUE
  disableTestMode <<- function () testMode <<- FALSE
  testModeOn <<- function () testMode

} )

studentPath <- function ( student, file ) {
  if ( testModeOn() )
    paste0( './test-data/', student, '/', file )
  else
    paste0( '~', student, '/', getPreference( 'individual' ), '/', file )
}

teamPath <- function ( student, file ) {
  if ( testModeOn() )
    paste0( './test-data/team1/', file )
  else
    paste0( '~', student, '/', getPreference( 'teamfolder' ), '/', file )
}

instructorPath <- function ( student, file )
  paste0( getPreference( 'grading' ), '/', student, '--', file )

gradedPath <- function ( student, file )
  studentPath( student, paste0( 'graded--', file ) )

studentNames <- function () {
  if ( testModeOn() )
    strsplit( getPreference( 'students' ), '\\s+' )[[1]]
  else
    c( 'student1', 'student2' )
}
