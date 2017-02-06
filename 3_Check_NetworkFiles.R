##### PURPOSE #####
## This script compares JSON and REDCap data and identifies missing data. ##
## redCapIds.csv is maintained by hand. The script compiles networkIds. ##

##### LIBRARIES & SET-UP #####
## Libraries ##
# For substrings.
suppressMessages(library(stringr))
# For %nin%
suppressMessages(library(Hmisc))
# For replace_number
suppressMessages(library(qdap))

# Read settings file.
# It's not guaranteed whether the working directory is Scripts/ or Scripts/Process, so try both paths to settings.
tryCatch({
  con <- file("configure_networkscripts.txt")
  source(con)
}, error = function(e) {
  con <- file("../configure_networkscripts.txt")
  source(con)
}, finally = {
  close(con)
})

## Set folder name shortcut. ##
# If you want to test the script, change test.check.folder to TRUE in the settings file.
if (test.check.folder == TRUE) {
  folder <- folder.check.test
} else {
  folder <- folder.check.default
}

## List all filenames. ##
files <- c()
folders <- list.dirs(path = paste0(folder),recursive = FALSE)
# For folders in Analysis Ready,
for (i in 1:length(folders)) {
  # If it is a 'V#' folder,
  if (identical(str_sub(folders[i],-2,-2),"V")) {
    # Add all its filenames to a list.
    files <- append(files,list.files(path = folders[i],pattern = "*.json",recursive = FALSE,full.names = TRUE))
  }
}

##### COMPILE networkIds #####
## Pull network IDs and dates from filenames ##
# Put files in a dataframe.
files <- as.data.frame(files,stringsAsFactors = FALSE)
# The RADAR ID and visit number are in the file name.
files$networkId <- as.integer(paste0(str_sub(files$files,-39,-36),paste0(0,str_sub(files$files,-15,-15))))
# The date is in the file name.
files$date <- str_sub(files$files,-13,-6)
# Convert the date to date so you can sort it.
files$date <- as.Date(files$date,"%Y%m%d")
# Add slashes so it matches the redCapId format.
files$date <- paste(str_sub(files$date,6,7),str_sub(files$date,9,10),str_sub(files$date,1,4),sep = "/")
# Sort by ID.
files <- files[order(files$networkId),2:3]
# Sort by visit number.
files <- files[order(str_sub(files$networkId,5,6)),]
# Sort by date.
networkIds <- files[order(files$date),1:2]
# Remove any files that are indicated as to-be-skipped.
networkIds <- networkIds[(networkIds$networkId %nin% networkSkipIds),]
# Note duplicates.
networkIdDuplicates <- networkIds[which(duplicated(networkIds$networkId) | duplicated(networkIds$networkId, fromLast = TRUE)),]

##### LOAD redCapIds #####
## Set path to redCapIds.csv ##
# If you want to test the script, set test.check.redCap to TRUE in the settings file.
if (test.check.redCap == TRUE) {
  redCapIdPath <- redCapIdPath.test
} else {
  redCapIdPath <- redCapIdPath.default
}

## Load redCapIds.csv.
redCapIds <- read.csv(redCapIdPath,stringsAsFactors = FALSE,header = TRUE)
# Remove files that are known to be missing.
redCapIds <- redCapIds[(redCapIds$redCapId %nin% redCapSkipIds),]
# Note duplicates.
redCapIdDuplicates <- redCapIds[which(duplicated(redCapIds$redCapId) | duplicated(redCapIds$redCapId, fromLast = TRUE)),]

##### COMPARE & IDENTIFY MISSING DATA #####
# Select rows for which there is health survey data but not network data.
redCapIdWarn <- redCapIds[-which(redCapIds$redCapId %in% networkIds$networkId),]
# Select rows for which there is network data but not health survey data.
networkIdWarn <- networkIds[-which(networkIds$networkId %in% redCapIds$redCapId),]

#### RESULTS #####
# Missing network data.
if (length(redCapIdWarn$redCapId) == 0) {
  writeLines("  No health surveys without corresponding network interview data.")
} else {
  # If there are files missing, indicate how many and which.
  writeLines(paste(" ",capitalize(replace_number(length(redCapIdWarn$redCapId))),"health survey(s) without corresponding network interview data:"))
  writeLines(paste0("    ",redCapIdWarn$redCapId,",",redCapIdWarn$date))
}
writeLines("")

# Missing health survey data.
if (length(networkIdWarn$networkId) == 0) {
  writeLines("  No network interviews without corresponding health survey data.")
} else {
  # If there are data missing, indicate how many and which.
  writeLines(paste(" ",capitalize(replace_number(length(networkIdWarn$networkId))),"network interview(s) without corresponding health survey data:"))
  writeLines(paste0("    ",networkIdWarn$networkId,",",networkIdWarn$date))}

# Duplicated REDCap IDs.
if (length(redCapIdDuplicates$redCapId) > 0) {
  writeLines("")
  writeLines(paste(" ",capitalize(replace_number(length(redCapIdDuplicates$redCapId))),"duplicate REDCap IDs:"))
  writeLines(paste0("    ",redCapIdDuplicates$redCapId,",",redCapIdDuplicates$date))
}

# Duplicated network IDs.
if (length(networkIdDuplicates$networkId) > 0) {
  writeLines("")
  writeLines(paste(" ",capitalize(replace_number(length(networkIdDuplicates$networkId))),"duplicate Network Interview IDs:"))
  writeLines(paste0("    ",networkIdDuplicates$networkId,",",networkIdDuplicates$date))
}
