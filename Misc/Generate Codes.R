##### PURPOSE #####
## This script creates validation codes used when loading previous network data into netCanvas-R.
## It also copies the most recent JSON file for each RADAR ID to a folder.
## This folder must be manually compressed to jsonData.7z and moved to /Follow-Up Data.
## It replaces the previous jsonData.7z in that folder.

## Libraries ##
library(rjson)
library(stringr)

# Read settings file.
# Try to read from this directory. If it's not there, try the next directory up.
tryCatch({
  con <- file("configure_miscscripts.txt")
  source(con)
}, error = function() {
  con <- file("../configure_miscscripts.txt")
  source(con)
}, finally = {
  close(con)
})

##### SELECT FILES TO READ #####
files <- c()
folders <- list.dirs(path = paste0(folder.in.codes),recursive = FALSE)
for (i in 1:length(folders)) {
  if (identical(str_sub(folders[i],-2,-2),"V")) {
    files <- append(files,list.files(path = folders[i],pattern = "*.json",recursive = FALSE,full.names = TRUE))
  }
}

##### READ FILES #####
radarID = c();finishtime = c()

for (i in 1:length(files)) {
  json <- fromJSON(file = files[i])
  radarID[i] <- json$nodes[[1]]$radar_id
  finishtime[i] <- json$nodes[[1]]$int_ftime_t0
}

##### WRITE VALIDATION CODES TO .CSV #####
Codes <- data.frame(radarID,finishtime,files,stringsAsFactors = FALSE)
Codes$shortPath <- str_sub(Codes$files,-39)
Codes <- Codes[order(finishtime,decreasing = TRUE),]
Codes <- subset(Codes,!duplicated(Codes[,"radarID"]))
Codes$validcode <- str_sub(Codes$finishtime,start = -5)
write.csv(Codes[,c("radarID","validcode")],file = validCodesPath,row.names = FALSE)
writeLines(paste("  Validation codes written to\n",validCodesPath))

##### COPY MOST RECENT JSON FILES TO jsonData #####
if (create.jsonData == TRUE) {
  previousData <- list.files(jsonDataPath,full.names = TRUE)
  if (length(previousData) > 0) {for (i in 1:length(previousData)) {file.remove(previousData[i])}}
  for (i in 1:length(Codes$files)) {file.copy(Codes$files[i],paste0(jsonDataPath,Codes$shortPath[i]))}
  writeLines(paste("\n  The most recent JSON file for each participant was copied to\n",
  "",jsonDataPath,"\n  Compress these files with 7-Zip and replace Network Data/Follow-Up Data/jsonData.7z."))
} else {
  writeLines(paste("\n  The most recent JSON file for each participant was NOT copied to\n",
  "",jsonDataPath,"\n  Enable \"create.jsonData\" in the settings file to copy files."))
}
