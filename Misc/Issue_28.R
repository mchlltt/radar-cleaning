## This script identifies errors that result from Issue #28 as described
## on the RADAR Protocol GitHub repository. The text of the initial error report is pasted below:

# I've discovered that for all longitudinal surveys, previously elicited alters
# that are pulled over on the "drugs with" or "sex with" name generator do not
# automatically have a drug or sex edge created for them, and so they are not
# automatically highlighted on the canvas select screens for drug or sex partners.
# (To clarify, the edge is correctly created for newly created alters; only previously
# elicited alters have this issue.) We are worried that, especially for those with large
# networks, they will be more likely to forget to tap everyone and so we will not get
# to collect any of the sex edge or drug edge attributes.
# Pat is looking into the actual prevalence of this issue, and plans to create an
# attributeless drug or sex edge for any alters that were created on "drugs with" or
# "sex with" but did not end up having a drug or sex edge created because the participant
# failed to tap them on the appropriate screen.

## Because this issue was not fixed, it is necessary to check regularly whether there are any
## missing sex or drug edges. However, it is not quite as simple as creating every edge where
## the name generator was "sex with" or "drugs with" where the edge does not exist. This is because
## participants will occasionally, for instance, name an alter on the "sex with" name generator,
## then realize later on that they did not actually have sex with that alter in the past 6 months
## and remove the edge. Thus, for each case where the name generator implies that an edge should
## exist but it does not exist, this script will output identifying information about the situation.
## The person running the script must then manually inspect the corresponding JSON file. Usually,
## the best way to proceed is by looking through the `log` portion of the JSON file to see
## whether an edge was created and then deleted. If an edge is in fact missing, add a note
## to the Data Error Log and create a correction in corrections.json to add that edge.
## Regardless of whether there was an actual issue, add the interview ID to 'skipfiles28' in the
## Misc Scripts settings file.


## Libraries ##
# For substrings
library(stringr)
# For reading JSON files.
library(rjson)

# Read settings file. Try multiple paths to the settings file.
tryCatch({
  source("configure_miscscripts.R")
}, error = function(e) {
  return(source("../configure_miscscripts.R"))
}, warning = function(e) {
  return(source("../configure_miscscripts.R"))
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