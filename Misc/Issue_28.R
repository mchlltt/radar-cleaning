### This script identifies errors that result from Issue #28 as described on the RADAR Protocol GitHub repository.
### To be run at the beginning of each month until the issue is resolved.

## Libraries ##
# For substrings
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


## Select files to consider. ##
files <- c()
folders <- list.dirs(path = paste0(folder.in.28),recursive = FALSE)
for (i in 1:length(folders)) {
  if (identical(str_sub(folders[i],-2,-2),"V")) {
    if (as.integer(str_sub(folders[i],-1,-1)) != 1) {
      files <- append(files,list.files(path = folders[i],pattern = "*.json",recursive = FALSE,full.names = TRUE))
    }
  }
}

sink(paste0(folder.in.28,"issue28.csv"))
for (i in 1:length(files)) {
  json <- fromJSON(file = files[i])
  visitnumber <- json$nodes[[1]]$visit_number
  radarID <- json$nodes[[1]]$radar_id
  for (j in 1:length(json$edges)) {
    if (identical(json$edges[[j]]$ng_t0,"drug use")) {
      if (!is.null(json$edges[[j]]$elicited_previously)) {
        print(paste("",radarID,paste0("0",visitnumber),json$edges[[j]]$to,"drugs","ng","",sep = ","))
      }
    }
    if (identical(json$edges[[j]]$ng_t0,"sex with")) {
      if (!is.null(json$edges[[j]]$elicited_previously)) {
        print(paste("",radarID,paste0("0",visitnumber),json$edges[[j]]$to,"sex","ng","",sep = ","))
      }
    }
    if (identical(json$edges[[j]]$type,"Drugs")) {
      print(paste("",radarID,paste0("0",visitnumber),json$edges[[j]]$to,"drugs","edge","",sep = ","))
    }
    if (identical(json$edges[[j]]$type,"Sex")) {
      if (json$edges[[j]]$from == 0) {
        print(paste("",radarID,paste0("0",visitnumber),json$edges[[j]]$to,"sex","edge","",sep = ","))
      }
    }
  }
}

issue28 <- read.csv(paste0(folder.in.28,"issue28.csv"),header = FALSE,stringsAsFactors = FALSE,quote = "")
sink();unlink(paste0(folder.in.28,"issue28.csv"))
issue28$V1 <- paste0(issue28$V2,issue28$V3,issue28$V4,issue28$V5)
issue28 <- subset(issue28[!(duplicated(issue28[,"V1"]) | duplicated(issue28[,"V1"],fromLast = TRUE)),])
issue28 <- subset(issue28,issue28$V6 == "ng",select = c(V2,V3,V4,V5))
issue28 <- subset(issue28,!(paste0(issue28$V2,"0",issue28$V3) %in% skipFiles28))
if (length(issue28$V2) == 0) {
  writeLines(paste0("  No issues related to Issue 28 were found."))
} else {
  writeLines("  Potential Issue(s) Found:");writeLines(paste(paste("    RADAR ID:",issue28$V2),paste("Visit:",as.integer(issue28$V3)),paste("Alter Node ID:",issue28$V4),paste("Missing Edge Type:",issue28$V5),sep = "; "))
  writeLines("  Please inspect these files to determine whether there should
  be an edge of the listed type between the Ego and the listed node.
  If so, add this edge via the cleaning script. If not, add the interview ID
  (RADAR ID + 0 + Visit Number) to 'skipFiles28' in the Misc Scripts settings file.")
}