##### PURPOSE #####
## This script transfers all files from the Incoming folder to the Raw folder. ##
## Each file is renamed by RADAR ID, date, and visit number to the proper Raw/V* folder. ##
## Each file is also copied as-is to the proper Raw/V*/Unedited folder. ##

##### LIBRARIES & SET-UP #####
## Libraries ##
# To read JSON files.
library(rjson)
# For substrings.
library(stringr)

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

## Set folder name shortcuts. ##
# If you want to use a test Incoming folder, set test.in.trans in the settings file to TRUE.
if (test.in.trans == TRUE) {
  folder.in <- folder.in.trans.test
} else {
  folder.in <- folder.in.trans.default
}

# If you want to use a test Raw folder, set test.out.trans in the settings file to TRUE.
if (test.out.trans == TRUE) {
  folder.out <- folder.out.trans.test
} else {
  folder.out <- folder.out.trans.default
}

##### SELECT FILES TO TRANSFER #####
# Total files found (except .db files).
numAllFiles <- length(list.files(path = folder.in)) - length(list.files(path = folder.in,pattern = "*.db"))
# List of JSON files.
files <- list.files(path = folder.in,pattern = "*.json")
# Number of JSON files.
numFiles <- length(files)
# Number of files that aren't JSON files.
nonJSON <- numAllFiles - numFiles
# Initialize number transferred counter.
transFiles <- 0
# Initialize number skipped counter.
numSkipped <- 0

##### TRANSFER FILES #####
## For each file in the Incoming folder, copy renamed version to Raw/V* and as-is version to Raw/V*/Unedited. ##
if (numFiles > 0) {
  for (i in 1:numFiles) {
    # Make sure that the file size > 0 kb.
    if (file.info(paste0(folder.in,files[i]))[1,1] > 0) {
      # Read the file.
      json <- fromJSON(file = paste0(folder.in,files[i]))
      # Make sure the file isn't a stub.
      if (length(json$nodes) > 0 & length(json$log) >= 75) {
        # Get RADAR ID and interview date from JSON.
        radarID <- json$nodes[[1]]$radar_id
        intdate <- gsub("-","",substr(json$log[[75]]$eventTime,1,10))

        # Default visit number of 1.
        visitNumber <- 1

        # If there is a visit number on the ego node, overwrite the default visit number.
        if (!is.null(json$nodes[[1]]$visit_number)) {
          visitNumber <- json$nodes[[1]]$visit_number
        }


        # Copy the file to Raw/V#/Unedited/.
        file.copy(paste0(folder.in,files[i]),paste0(folder.out,"V",visitNumber,"/Unedited/",files[i]))

        # If the file doesn't have 'Interview' in the name,
        if (length(grep('Interview', files[i])) == 0) {
          # Copy a renamed file to Raw/V#/.
          file.rename(paste0(folder.in,files[i]),paste0(folder.out,"V",visitNumber,"/",paste(radarID,paste0("Network_Interview_V",visitNumber),paste0(intdate,".json"),sep = "_")))
        } else {
          file.remove(paste0(folder.in,files[i]))
        }

        # Increment counter.
        transFiles <- transFiles + 1
      } else {
        # If it's a stub, skip it and increment number skipped.
        numSkipped <- numSkipped + 1
      }
    } else {
      # If the file is 0 kb, skip it and increment number skipped.
      numSkipped <- numSkipped + 1
    }
  }
}

##### RESULTS #####
## Print results. ##
if (numFiles == 0 & numAllFiles == 0) {
  writeLines("  No new files to transfer.")
} else {
  # Write how many transferred, skipped, or non-JSON files there were.
  writeLines(paste(" ",transFiles,"of",numFiles,"JSON file(s) in the Incoming folder were transferred."))
  if (numSkipped > 0) {writeLines(paste(" ",numSkipped,"of",numFiles,"JSON file(s) were skipped."))}
  if (nonJSON > 0) {writeLines(paste(" ",nonJSON,"Non-JSON file(s) were left in the folder."))}}