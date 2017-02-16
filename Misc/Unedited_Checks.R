# PURPOSE: This script addressed a complicated issue. A potential data issue can arise
# when two files are downloaded for the same participant ID in the same day. Most often, this happens
# when the file is downloaded, then the program is closed and reopened and downloaded again. In this case,
# it doesn't matter which of these two files ends up in the analysis set. Rarely, however, data may be
# saved with a substantial portion of the interview incomplete and then saved again once the interview is complete.
# If both of these saves have the same RADAR ID and the same date, it is not guaranteed that the more complete file will
# end up in the Raw/V*/ folder. This is because, when the files are transferred from Incoming to Raw, both files will have the same
# filename, and one will overwrite the other. However, both files are still present in Raw/Unedited, because
# they are guaranteed to have different filenames by merit of having a different download time. Thus, this script
# identifies cases where there are two files for the same RADAR ID on the same date in the Raw/Unedited/ folder.
# It then compares the length of the log in each file to determine whether there may be a significant difference between the two files.
# It then takes the smaller set of potential issues and compares edges and nodes.
# If there are two files for the same ID on the same day with differences in their edges and/or nodes, the script will print the RADAR ID
# and file path. For each set, the first task is to open both files in Raw/Unedited/ and determine whether there is actually
# a significant difference between the two files.
#
# If there *is* a significant difference, which is a fairly rare occurance,
# the user must check the file corresponding to this RADAR ID and date in the Raw/ folder. If the file in the Raw/ folder is already
# the more up-to-date file, no corrections need to be made. However, if the less up-to-date file is in Raw/, the user should
# copy the more up-to-date file from Raw/Unedited/ and paste it to the Incoming/ folder. Run the Transfer_NetworkFiles script and
# then run the Clean_NetworkFiles script with 'all' set to TRUE, to make sure that this file is the one cleaned and output in Analysis Ready/.
# Because this script should be run monthly, it should not be necessary to make any updates to validation codes or jsonData.7z.
# If run less frequently, there is a risk of having an out-of-date validation code in REDCap and file in jsonData.7z. However,
# when run monthly, any issues should be addressed several months before a participant's follow-up visit, so those corrections
# should be made automatically when the monthly scripts are next run.


## Libraries ##
# For comparing files and identifying duplicates.
suppressMessages(library(RecordLinkage))
# For substrings.
library(stringr)
# For reading JSON files.
library(rjson)

# Read settings file. Try multiple paths to the settings file.
tryCatch({
  source("configure_miscscripts.txt")
}, error = function(e) {
  return(source("../configure_miscscripts.txt"))
}, warning = function(e) {
  return(source("../configure_miscscripts.txt"))
})


## List all files in Unedited. ##
files1 <- list.files(path = paste0(folder.in.uned,"V1/Unedited/"),pattern = "*.json",recursive = FALSE,full.names = TRUE)
files2 <- list.files(path = paste0(folder.in.uned,"V2/Unedited/"),pattern = "*.json",recursive = FALSE,full.names = TRUE)
files3 <- list.files(path = paste0(folder.in.uned,"V3/Unedited/"),pattern = "*.json",recursive = FALSE,full.names = TRUE)
files4 <- list.files(path = paste0(folder.in.uned,"V4/Unedited/"),pattern = "*.json",recursive = FALSE,full.names = TRUE)
files5 <- list.files(path = paste0(folder.in.uned,"V5/Unedited/"),pattern = "*.json",recursive = FALSE,full.names = TRUE)
files <- c(files1,files2,files3,files4,files5)

## Values to pull from the files. ##
visitnumber <- c()
filesize <- c()
filename <- c()
radarID <- c()
date <- c()
sessionID <- c()
edgeCount <- c()
nodeCount <- c()
logLength <- c()

## Pull values from JSON files and their filenames. ##
for (i in 1:length(files)) {
  if (length(grep("Interview",files[i])) > 0) {
    next
  }
  json <- fromJSON(file = files[i])
  filesize[i] <- file.info(file = files[i])[,1]
  filename[i] <- files[i]
  if (is.null(json$sessionParameters)) {
    visitnumber[i] <- 1
  } else {
    visitnumber[i] <- json$nodes[[1]]$visit_number
  }
    radarID[i] <- paste0(json$nodes[[1]]$radar_id,"0",visitnumber[i])
    date[i] <- substring(json$log[[20]]$eventTime,1,10)
    sessionID[i] <- str_sub(files[i],-32,-17)
    edgeCount[i] <- length(json$edges)
    nodeCount[i] <- length(json$nodes)
    logLength[i] <- length(json$log)
}

## Narrow down to only files that could accidentally overwrite one another. ##
## That is: files with the same RADAR ID and visit number on the same date. ##
interviewID <- paste0(radarID,date)
unedCheck <- data.frame(interviewID,filesize,radarID,visitnumber,date,edgeCount,nodeCount,logLength,sessionID,filename,stringsAsFactors = FALSE)
unedDups <- subset(unedCheck[(duplicated(unedCheck[,"interviewID"]) | duplicated(unedCheck[,"interviewID"],fromLast = TRUE)),])
unedDups <- unedDups[order(unedDups$interviewID),]

## Use RecordLinkage to remove pairs that not sigificantly different from one another. ##
## That is, where  it doesn't matter which copy ended up getting renamed and analyzed. ##
linkage <- compare.dedup(unedDups,blockfld = c("interviewID","nodeCount","edgeCount","logLength"))
# The portion of the dataframe indicating matched interviews
pairs <- linkage$pairs[,1:2]
# Get the 'i' for each item that can be safely removed.
ids <- as.integer(append(pairs$id1,pairs$id2))

# Zero out the RADAR ID for the items that can be removed.
for (i in 1:length(unedDups$radarID)) {
  if (i %in% ids) {
    unedDups$radarID[i] <- 0
  }
}

## Keep only those that are in the set more than once.
toCheck <- subset(unedDups[(duplicated(unedDups$radarID) | duplicated(unedDups$radarID,fromLast = TRUE)),])

## Remove rows that are identical pairs (set to 0 above) or NA. ##
toCheck <- subset(toCheck[(toCheck$radarID > 0),])
toCheck <- subset(toCheck[!is.na(toCheck$radarID),])

## Remove interviews that we checked in a previous run of the script.
toCheck <- subset(toCheck[!(toCheck$radarID %in% duplicateSkips),])

# Now, with what we have left, inspect these files more closely.
jsons.nodes <- c()
jsons.edges <- c()

# Pull full node and edge lists.
for (i in 1:length(toCheck$radarID)) {
  json <- fromJSON(file = toCheck$filename[i])
  nodes <- json$nodes
  edges <- json$edges
  jsons.nodes[i] <- list(nodes)
  jsons.edges[i] <- list(edges)
}

# Create a list where RADAR IDs with potential issues will be collected.
potentialIssues <- c()

# If the RADAR ID of one row is the same as the RADAR ID of the previous row, check whether its nodes and edges are identical.
# If not, append the RADAR ID to potentialIssues
for (i in 2:length(toCheck$radarID)) {
  if (toCheck$radarID[i] == toCheck$radarID[i - 1]) {
    if (all(jsons.nodes[[i]][2:length(jsons.nodes[[i]])] %in% jsons.nodes[[i - 1]][2:length(jsons.nodes[[i - 1]])])) {
      if (all(jsons.edges[[i]] %in% jsons.edges[[i - 1]])) {
        next
      } else {
        potentialIssues <- append(potentialIssues, toCheck$radarID[i])
      }
    } else {
      potentialIssues <- append(potentialIssues, toCheck$radarID[i])
    }
  }
}

# Print only the rows where the RADAR ID was determined above to be a potential duplicate.
printCheck <- toCheck[,c(3, 10)][toCheck$radarID %in% potentialIssues,]

if (length(printCheck$radarID > 0)) {
  writeLines("  The following files should be examined.
  1. Locate and open them by their filepaths.
  2. Compare the files corresponding to the same visit number.
  3. Determine whether one file is more complete than the other.
  4. If one file is more complete than the other, find the file for this visit in the Raw/V*/ folder.
  5. Ensure that the contents of this file are the same file as the more complete file in the Raw/V*/Unedited folder.
  6. If the file in Raw/V*/ does not reflect the more complete data, copy the more complete file from Raw/V*/Unedited into Incoming.
  7. Then, run the processing scripts with 'all' set to TRUE, to ensure that the new data will overwrite the old data in Analysis Ready.

  8. Regardless of whether there is a legitimate issue or just a false positive,
  add the RADAR ID to 'duplicateSkips' in the Misc Scripts settings file so that
  it will be ignored in the future.")
  print(printCheck)
} else {
  writeLines("There are no potential issues that need to be inspected.")
}