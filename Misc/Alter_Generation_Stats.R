##### SET-UP AND LIBRARIES #####
## Libraries ##
# For reading/writing xlsx. Explicitly import its dependencies to avoid messages.
library(rJava)
library(xlsxjars)
library(xlsx)
# For reading JSON.
library(rjson)
# For substrings.
library(stringr)

# Read settings file. Try multiple paths to the settings file.
tryCatch({
  source("configure_miscscripts.R")
}, error = function(e) {
  return(source("../configure_miscscripts.R"))
}, warning = function(e) {
  return(source("../configure_miscscripts.R"))
})

## List all JSON files. ##
files <- c()
folders <- list.dirs(path = paste0(folder.in.alts),recursive = FALSE)
for (i in 1:length(folders)) {
  if (identical(str_sub(folders[i],-2,-2),"V")) {
    files <- append(files,list.files(path = folders[i],pattern = "*.json",recursive = FALSE,full.names = TRUE))
  }
}

##### DATA PULL #####
## Load in interviewer names for before it written in the file. ##
earlyInts <- read.csv(file = earlyIntsPath,stringsAsFactors = FALSE,colClasses = "character")
## Load in interviewer IDs for recoding later. ##
intIdR <- read.xlsx(intIdRPath,1,stringsAsFactors = FALSE,colClasses = "character")

## Pull information about alters elicited from each JSON file. ##
radarid <- c(); visitNumber <- c();intId <- c();countAlters <- c();elPrevPerc <- c();date <- c()

for (i in 1:length(files)) {
  json <- fromJSON(file = files[i])
  radarid[i] <- json$nodes[[1]]$radar_id
  date[i] <- gsub("-","/",substring(json$log[[50]]$eventTime,1,10))
  if (is.null(json$nodes[[1]]$visit_number)) {
    visitNumber[i] <- 1
    if (paste0(radarid[i],"01") %in% earlyInts$visitId) {
      rowNum <- which(earlyInts$visitId %in% paste0(radarid[i],"01"))
      intId[i] <- earlyInts$intName[rowNum]
    }
  } else {
    visitNumber[i] <- json$nodes[[1]]$visit_number
    intId[i] <- json$sessionParameters$interviewerID
  }
  countAlters[i] <- 0
  elPrev <- 0
  for (n in 1:length(json$edges)) {
    if (json$edges[[n]]$type == "Dyad" & !is.null(json$edges[[n]]$fname_t0)) {
      countAlters[i] <- countAlters[i] + 1
      if (!is.null(json$edges[[n]]$elicited_previously)) {
        elPrev <- elPrev + 1
      }
    }
  }
  if (elPrev > 1) {
    discard <- length(json$previousNetwork$nodes) - 1
    totalPrev <- elPrev + discard
    elPrevPerc[i] <- elPrev / totalPrev
  }
}

##### RECODING #####
## Add month variable. ##
month <- substring(date,1,7)

## Recode numerical interviewer IDs. ##
for (i in 1:length(intIdR$code)) {
  intId[intId == intIdR$code[i]] <- intIdR$name[i]
}

## Mark all non-current interviewers. ##
intId[intId %in% formerInts] <- "former/other"

##### EXPORT #####
## This data can be used to analyze interviewers' number ##
## of interviews + number of alters elicited at those interviews. ##
intData <- data.frame(radarid,countAlters,visitNumber,intId,elPrevPerc,date,month,stringsAsFactors = FALSE)
if (writeIntData == TRUE) {write.xlsx(intData[!(intId == "former/other"),],file = intDataPath,sheetName = "1",row.names = FALSE,showNA = FALSE)
  writeLines(paste("  Interviewer Stats written to\n",intDataPath))}
## This data serves as a proxy for participant engagement. For use by Data Manager. ##
engagement <- data.frame(radarid,countAlters,visitNumber,stringsAsFactors = FALSE)
if (writeEngagement == TRUE) {write.csv(engagement,file = engagementPath,row.names = FALSE)
  writeLines(paste("  Engagement Stats written to\n",engagementPath))}