## PURPOSE
# Match dyad edge info in Neo4j to names in JSON files by alter ID
# in order to match dyad edge info to partner names in REDCap.

## LIBRARIES
# For making dataframes from lists.
library(plyr)
# For substrings.
library(stringr)
# For connecting to Neo4j.
library(RNeo4j)
# For RADAR study scripts.
library(radar)
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

## PULL FROM Neo4j
writeLines("  Pulling alter data from Neo4j.")

# Update when new waves start!
maxWave <- 4
for (i in 1:maxWave) {
  dfName <- paste0('wave',i,'Att')
  assign(dfName, getDyadAttributes(graph,i))
}

wave1Att$radarid <- substr(wave1Att$alter.alter_id,1,4)
wave2Att$radarid <- substr(wave2Att$alter.alter_id,1,4)
wave3Att$radarid <- substr(wave3Att$alter.alter_id,1,4)
wave4Att$radarid <- substr(wave4Att$alter.alter_id,1,4)
wave1Att$visitNumber <- 1
wave2Att$visitNumber <- 2
wave3Att$visitNumber <- 3
wave4Att$visitNumber <- 4

# Extract all partners.
wave1Prt <- subset(wave1Att,(!is.na(wave1Att$seriousRel) | !is.na(wave1Att$sex)))
wave2Prt <- subset(wave2Att,(!is.na(wave2Att$seriousRel) | !is.na(wave2Att$sex)))
wave3Prt <- subset(wave3Att,(!is.na(wave3Att$seriousRel) | !is.na(wave3Att$sex)))
wave4Prt <- subset(wave4Att,(!is.na(wave4Att$seriousRel) | !is.na(wave4Att$sex)))

# Sort by recency of sex with each partner.
# Sort by last sex date and then RADAR ID.
wave1Prt <- wave1Prt[order(as.Date(wave1Prt$dyad_edge.lastSex,format = "%m/%d/%Y"),decreasing = TRUE),]
wave2Prt <- wave2Prt[order(as.Date(wave2Prt$dyad_edge.lastSex,format = "%m/%d/%Y"),decreasing = TRUE),]
wave3Prt <- wave3Prt[order(as.Date(wave3Prt$dyad_edge.lastSex,format = "%m/%d/%Y"),decreasing = TRUE),]
wave4Prt <- wave4Prt[order(as.Date(wave4Prt$dyad_edge.lastSex,format = "%m/%d/%Y"),decreasing = TRUE),]

wave1Prt <- wave1Prt[order(wave1Prt$radarid),]
wave2Prt <- wave2Prt[order(wave2Prt$radarid),]
wave3Prt <- wave3Prt[order(wave3Prt$radarid),]
wave4Prt <- wave4Prt[order(wave4Prt$radarid),]

# Assign ranks by most recent sex act
# Call every alter the most recent sex partner for their ego
wave1Prt$recent <- 1
wave2Prt$recent <- 1
wave3Prt$recent <- 1
wave4Prt$recent <- 1

# Then decrease this rank whenever there is a more recent sex partner for their ego
# Wave 1
for (i in 2:length(wave1Prt$radarid)) {
  if (!is.na(wave1Prt$dyad_edge.lastSex[i])) {
    if (wave1Prt$radarid[i] == wave1Prt$radarid[i - 1]) {
      wave1Prt$recent[i] <- wave1Prt$recent[i - 1] + 1
    }
  }
}

# Wave 2
for (i in 2:length(wave2Prt$radarid)) {
  if (!is.na(wave2Prt$dyad_edge.lastSex[i])) {
    if (wave2Prt$radarid[i] == wave2Prt$radarid[i - 1]) {
      wave2Prt$recent[i] <- wave2Prt$recent[i - 1] + 1
    }
  }
}

# Wave 3
for (i in 2:length(wave3Prt$radarid)) {
  if (!is.na(wave3Prt$dyad_edge.lastSex[i])) {
    if (wave3Prt$radarid[i] == wave3Prt$radarid[i - 1]) {
      wave3Prt$recent[i] <- wave3Prt$recent[i - 1] + 1
    }
  }
}

# Wave 4
for (i in 2:length(wave4Prt$radarid)) {
  if (!is.na(wave4Prt$dyad_edge.lastSex[i])) {
    if (wave4Prt$radarid[i] == wave4Prt$radarid[i - 1]) {
      wave4Prt$recent[i] <- wave4Prt$recent[i - 1] + 1
    }
  }
}

## MERGE ACROSS VISITS

allPrt <- Reduce(rbind,list(wave1Prt,wave2Prt,wave3Prt,wave4Prt))

# For those who did not have a most recent sex date, set "recent" to 0.
allPrt$recent[is.na(allPrt$dyad_edge.lastSex)] <- 0

## PULL FROM JSON FILES
writeLines("  Pulling alter names from JSON files.")

files <- c()
# Get the folders in Analysis Ready.
folders <- list.dirs(path = paste0(folder.partners),recursive = FALSE)
# And if they are a V# folder, add their files to the vector files.
for (i in 1:length(folders)) {
  if (identical(str_sub(folders[i],-2,-2),"V")) {
    files <- append(files,list.files(path = folders[i],pattern = "*.json",recursive = FALSE,full.names = TRUE))
  }
}

df <- list()

# Pull all dyad edges from JSON files to associate names to alter IDs.
for (i in 1:length(files)) {
  json <- fromJSON(file = files[i])
  radarid <- as.character(json$nodes[[1]]$radar_id)
  if (is.null(json$nodes[[1]]$visit_number)) {
    visitNumber <- 1
  } else {
    visitNumber <- json$nodes[[1]]$visit_number
  }
  alterEdges <- list()
  countAlters <- 0
  for (n in 1:length(json$edges)) {
    if (json$edges[[n]]$type == "Dyad" & !is.null(json$edges[[n]]$fname_t0)) {
      countAlters <- countAlters + 1
      alterEdges[[countAlters]] <- json$edges[[n]]
      alterEdges[[countAlters]]$alterid <- as.numeric(paste0(radarid,sprintf("%03d",json$edges[[n]]$to)))
      alterEdges[[countAlters]]$coords <- NULL
    }
  }
  df[[i]] <- ldply(alterEdges,data.frame)
  df[[i]]$radarid <- radarid
  df[[i]]$visitNumber <- visitNumber
}

# Turn these lists of lists into a big dataframe.
nameData <- ldply(df,data.frame)[,c("alterid","visitNumber","fname_t0","lname_t0","nname_t0")]
nameData$fname_t0 <- as.character(nameData$fname_t0)
nameData$lname_t0 <- as.character(nameData$lname_t0)
nameData$nname_t0 <- as.character(nameData$nname_t0)
nameData$alter.alter_id <- paste0(nameData$alterid,'0',nameData$visitNumber)
nameData$visitNumber <- NULL

## MATCH ALTER IDS
# Match alter IDs from neo4j and JSON files to associate names with the neo4j data.
writeLines("  Combining Neo4j and JSON file data.")

# Find the rows in nameData that correspond to the same alter ID, then adopt those name values
allPrtJoin <- merge.data.frame(allPrt,nameData,by = "alter.alter_id")

# Create a list of the alter IDs that are included more than once.
repeatPartners <- allPrtJoin[which(duplicated(allPrtJoin$alterid) | duplicated(allPrtJoin$alterid, fromLast = TRUE)),'alterid']

# Default value of FALSE.
allPrtJoin$repeated <- FALSE

# If the alter ID is in the list of repeat partners, override the default to TRUE.
allPrtJoin$repeated[allPrtJoin$alterid %in% repeatPartners] <- TRUE

## EXPORT
allPrtJoin <- allPrtJoin[order(allPrtJoin$alter.alter_id),]
write.csv(allPrtJoin,file = partnerNamePath,row.names = FALSE)
writeLines(paste("  Partner name data written to\n","",partnerNamePath))