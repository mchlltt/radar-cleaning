##### PURPOSE #####
## This script reads JSON files in the Raw folders and cleans them for analysis. ##
## Non-date errors are recorded in the Error Log and processed via corrections.xlsx. ##
## Dates are amended in all files to correct errors and to uniformize formatting. ##
## A corrected version of each JSON is then saved in the Analysis Ready folders. ##

##### LIBRARIES & SET-UP #####
## Libraries ##
# For import from xlsx. Require its dependencies explicitly to avoid messages.
library(rJava)
library(xlsxjars)
library(xlsx)
# For substrings.
library(stringr)
# For concatenation.
library(stringi)
# For reading JSON files.
library(rjson)

# Read settings file. Try multiple paths to the settings file.
tryCatch({
  source("configure_networkscripts.txt")
}, error = function(e) {
  return(source("../configure_networkscripts.txt"))
}, warning = function(e) {
  return(source("../configure_networkscripts.txt"))
})

## Set folder name shortcuts. ##
# To use a test Raw folder, set test.in.clean to TRUE.
if (test.in.clean) {
  folder.in <- folder.in.clean.test
} else {
  folder.in <- folder.in.clean.default
}

# To use a test Analysis Ready folder, set test.out.clean to TRUE.
if (test.out.clean) {
  folder.out <- folder.out.clean.test
} else {
  folder.out <- folder.out.clean.default
}

## Read in corrections.csv ##
# To use a test corrections file, set correctionsPath.test to TRUE.
if (test.clean.corrections) {
  correctionsPath <- correctionsPath.test
} else {
  correctionsPath <- correctionsPath.default
}

# Read the first sheet of the corrections.xlsx file.
corrections <- read.xlsx2(correctionsPath,1,
                        header = TRUE,stringsAsFactors = FALSE,colClasses = "character")

##### SELECT FILES TO PROCESS #####
## List all raw files. ##

files <- c()
folders <- list.dirs(path = paste0(folder.in),recursive = FALSE)
# For folders in Raw,
for (i in 1:length(folders)) {
  # If it is a V# folder,
  if (identical(str_sub(folders[i],-2,-2),"V")) {
    # Add all the filenames in the folder to a list.
    files <- append(files,list.files(path = folders[i],pattern = "*.json",recursive = FALSE,full.names = TRUE))
  }
}

# Determines which files will be cleaned.
if (all) {
  # If you want to reclean all files, change all to TRUE.
  writeLines("  Processing ALL files. (If this isn't what you wanted, hit CTRL+C to abort,
  then set 'all' to FALSE in the settings file.)")
} else {
  # By default, today and the prior 4 days files are cleaned. To change this number, change daysBeforeToday in the settings file.
  # daysBeforeToday = 0 will process today's files only.
  writeLines(paste("  Processing today's and the prior",daysBeforeToday,"days' network interview files."))
  files <- files[which(Sys.Date() - as.Date(str_sub(files,-13,-6),"%Y%m%d") <= daysBeforeToday)]
}

##### PROCESS FILES #####
## Initialize files processed and skipped counters.
numCopyFilesV1 <- 0
numCopyFilesV2 <- 0
numCopyFilesV3 <- 0
numCopyFilesV4 <- 0
numSkipped <- 0
if (length(files) == 0) {
  writeLines("\n  No files found to clean! Please set all to TRUE or increase daysBeforeToday.")
} else {
  ## For each file, import from JSON. ##
  for (i in 1:length(files)) {
    json <- fromJSON(file = files[i])
    # Assume it does not need corrected.
    needsCorrected <- FALSE
    ## Check whether the file needs non-date corrections by seeing if its radar id+int_ftime combo is in the corrections spreadsheet.
    if (paste0(json$nodes[[1]]$radar_id,json$nodes[[1]]$int_ftime_t0) %in% paste0(corrections$radaridis,corrections$ftime)) {
      needsCorrected <- TRUE
      rowNum <- which(paste0(corrections$radaridis,corrections$ftime) %in% paste0(json$nodes[[1]]$radar_id,json$nodes[[1]]$int_ftime_t0))
    }
    ## If corrections are needed, apply those that are needed. ##
    if (needsCorrected) {
      ## If the file needs to be skipped, add a tally to the number skipped and move to the next file. ##
      if (nchar(corrections$skip[rowNum]) > 0) {
        numSkipped <- numSkipped + 1
        next}
      ## Fix radar IDs. ##
      if (!identical(json$nodes[[1]]$radar_id,corrections$radaridshould[rowNum])) {
        json$nodes[[1]]$radar_id <- corrections$radaridshould[rowNum]
      }
      ## Delete nodes. ##
      if (nchar(corrections$nodedelstart[rowNum]) > 0) {
        # Deletes a range from start to stop.
        nodeNumStart <- corrections$nodedelstart[rowNum]
        nodeNumStop <- corrections$nodedelstop[rowNum]
        json$nodes[nodeNumStart:nodeNumStop] <- NULL
      }
      ## Delete edges. ##
      if (nchar(corrections$edgedelstart[rowNum]) > 0) {
        # Deletes a range from start to stop.
        edgeNumStart <- corrections$edgedelstart[rowNum]
        edgeNumStop <- corrections$edgedelstop[rowNum]
        json$edges[edgeNumStart:edgeNumStop] <- NULL
      }
      ## Fix sex edges. ##
      if (nchar(corrections$sexedge[rowNum]) > 0) {
        # Find the edge with sexedge's id.
        for (j in 1:length(json$edges)) {
          if (json$edges[[j]]$id == corrections$sexedge[rowNum]) {
            edgeNum <- j
          }
        }
        json$edges[[edgeNum]]$sex_last_t0 <- corrections$lastsexshould[rowNum]
        json$edges[[edgeNum]]$loc_met_cat_t0 <- corrections$locmetcatshould[rowNum]
        json$edges[[edgeNum]]$loc_met_detail_t0 <- corrections$locmetdetailshould[rowNum]
      }
      ## Fix residence edges. ##
      if (nchar(corrections$resedge1[rowNum]) > 0) {
        # Find the edge with resedge1's id.
        for (j in 1:length(json$edges)) {
          if (json$edges[[j]]$id == corrections$resedge1[rowNum]) {
            edgeNum <- j
          }
        }
        ## If the category needs to be changed to Illinois, but not Chicago, small workaround for commas.
        if (identical(corrections$rescatshould1[rowNum],"Illinois but not Chicago")) {
          json$edges[[edgeNum]]$res_cat_p_t0 <- paste("Illinois","but not Chicago",sep = ", ")
        } else {
          # Otherwise just set to rescatshould.
          json$edges[[edgeNum]]$res_cat_p_t0 <- corrections$rescatshould1[rowNum]
        }
        # If it's not in Chicago, clear out any Chicago location.
        if (!identical(json$edges[[edgeNum]]$res_cat_p_t0,"Chicago")) {
          json$edges[[edgeNum]]$res_chicago_location_p_t0 <- NULL
        } else {
          # Otherwise set the Chicago location to reschishould.
          json$edges[[edgeNum]]$res_chicago_location_p_t0 <- corrections$reschishould1[rowNum]
        }
        # If it isn't Illinois, but not Chicago, clear out any city.
        if (!identical(json$edges[[edgeNum]]$res_cat_p_t0,"Illinois, but not Chicago")) {
          json$edges[[edgeNum]]$res_city_p_t0 <- NULL
        } else {
          # Otherwise set the city.
          json$edges[[edgeNum]]$res_city_p_t0 <- corrections$rescityshould1[rowNum]
        }
      }
      # See comments on resedge1 above for explanation.
      if (nchar(corrections$resedge2[rowNum]) > 0) {
        for (j in 1:length(json$edges)) {
          if (json$edges[[j]]$id == corrections$resedge2[rowNum]) {
            edgeNum <- j
          }
        }
        if (identical(corrections$rescatshould2[rowNum],"Illinois but not Chicago")) {
          json$edges[[edgeNum]]$res_cat_p_t0 <- paste("Illinois","but not Chicago",sep = ", ")
        } else {
          json$edges[[edgeNum]]$res_cat_p_t0 <- corrections$rescatshould2[rowNum]
        }
        if (!identical(json$edges[[edgeNum]]$res_cat_p_t0,"Chicago")) {
          json$edges[[edgeNum]]$res_chicago_location_p_t0 <- NULL
        } else {
          json$edges[[edgeNum]]$res_chicago_location_p_t0 <- corrections$reschishould2[rowNum]
        }
        if (!identical(json$edges[[edgeNum]]$res_cat_p_t0,"Illinois, but not Chicago")) {
          json$edges[[edgeNum]]$res_city_p_t0 <- NULL
        } else {
          json$edges[[edgeNum]]$res_city_p_t0 <- corrections$rescityshould2[rowNum]
        }
      }
      # See comments on resedge1 above for explanation.
      if (nchar(corrections$resedge3[rowNum]) > 0) {
        for (j in 1:length(json$edges)) {
          if (json$edges[[j]]$id == corrections$resedge3[rowNum]) {
            edgeNum <- j
          }
        }
        if (identical(corrections$rescatshould3[rowNum],"Illinois but not Chicago")) {
          json$edges[[edgeNum]]$res_cat_p_t0 <- paste("Illinois","but not Chicago",sep = ", ")
        } else {
          json$edges[[edgeNum]]$res_cat_p_t0 <- corrections$rescatshould3[rowNum]
        }
        if (!identical(json$edges[[edgeNum]]$res_cat_p_t0,"Chicago")) {
          json$edges[[edgeNum]]$res_chicago_location_p_t0 <- NULL
        } else {
          json$edges[[edgeNum]]$res_chicago_location_p_t0 <- corrections$reschishould3[rowNum]
        }
        if (!identical(json$edges[[edgeNum]]$res_cat_p_t0,"Illinois, but not Chicago")) {
          json$edges[[edgeNum]]$res_city_p_t0 <- NULL
        } else {
          json$edges[[edgeNum]]$res_city_p_t0 <- corrections$rescityshould3[rowNum]
        }
      }
      ## Fix alter names. ##
      if (nchar(corrections$nameedge[rowNum]) > 0) {
        # Find nameedge by id.
        for (j in 1:length(json$edges)) {
          if (json$edges[[j]]$id == corrections$nameedge[rowNum]) {
            edgeNum <- j
          }
        }
        json$edges[[edgeNum]]$fname_t0 <- corrections$fnameshould[rowNum]
        json$edges[[edgeNum]]$lname_t0 <- corrections$lnameshould[rowNum]
        json$edges[[edgeNum]]$nname_t0 <- corrections$nnameshould[rowNum]
        json$edges[[edgeNum]]$label <- corrections$labelshould[rowNum]
      }
      ## Fix alter ages. ##
      if (nchar(corrections$ageedge[rowNum]) > 0) {
        # Find agedge by id.
        for (j in 1:length(json$edges)) {
          if (json$edges[[j]]$id == corrections$ageedge[rowNum]) {
            edgeNum <- j
          }
        }
        json$edges[[edgeNum]]$age_p_t0 <- corrections$ageshould[rowNum]
      }
      ## Fix interviewer ID. ##
      if (nchar(corrections$intshould[rowNum]) > 0) {
        json$sessionParameters$interviewerID <- corrections$intshould[rowNum]
      }
      ## Fix visit number. ##
      if (nchar(corrections$visitshould[rowNum]) > 0)  {
        json$nodes[[1]]$visit_number <- as.integer(corrections$visitshould[rowNum])
      }
      ## Fix seed status. ##
      if (nchar(corrections$seedshould[rowNum]) > 0) {
        json$nodes[[1]]$seed_status_t0 <- corrections$seedshould[rowNum]
      }
      ## Fix ptp gender. ##
      if (nchar(corrections$ptpgendershould[rowNum]) > 0) {
        json$nodes[[1]]$gender_k <- corrections$ptpgendershould[rowNum]
      }
      ## Assign new alter IDs. ##
      # This is necessary when a follow-up visit is run without loading in the most recent data,
      # because otherwise, you will end up with duplicate alter IDs.
      # All new alters from the messed up visits need to have their IDs incremented so that they start
      # *after* the last existing alter ID.
      if (nchar(corrections$renumberoffset[rowNum]) > 0) {
        # The first alter that needs its ID changed.
        renumberIdStart <- as.integer(corrections$renumberidstart[rowNum])
        # The number all affected alters need to be incremented by.
        renumberOffset <- as.integer(corrections$renumberoffset[rowNum])
        # For each edge,
        for (j in 1:length(json$edges)) {
          # Check if "from" is at or above the threshold to need to be increased.
          if (json$edges[[j]]$to >= renumberIdStart) {
            json$edges[[j]]$to <- json$edges[[j]]$to + renumberOffset
          }
          # Check if "to" is at or above the threshold to need to be increased.
          if (json$edges[[j]]$from >= renumberIdStart) {
            json$edges[[j]]$from <- json$edges[[j]]$from + renumberOffset
          }
        }
        # For nodes at or above the threshold, increment their ID.
        for (k in 1:length(json$nodes)) {
          if (json$nodes[[k]]$id >= renumberIdStart) {
            json$nodes[[k]]$id <- json$nodes[[k]]$id + renumberOffset
          }
        }
        # Add the offset to the highest number in the reserved_ids array.
        renumberHighest <- renumberOffset + max(json$nodes[[1]]$reserved_ids)
        # Change the reserved_ids array to have a maximum of the number calculated above.
        json$nodes[[1]]$reserved_ids <- 0:renumberHighest
      }
      ## Create edges. ##
      ## Suppressed warning: "Coercing LHS to a list" ##
      # It's really tricky to write a new edge such that it looks indistinguishable from edge created during the interview.
      # Thus, using this odd method of creating the new edge and assigning values to it.
      # It's not pretty and requires suppressing a warning, but it turns out looking exactly right.
      if (nchar(corrections$newedgeid1[rowNum]) > 0) {
        newedgenumber <- length(json$edges) + 1
        json$edges[newedgenumber] <- toJSON(c())
        suppressWarnings(json$edges[[newedgenumber]]$id <- as.integer(corrections$newedgeid1[rowNum]))
        json$edges[[newedgenumber]]$type <- corrections$newedgetype1[rowNum]
        json$edges[[newedgenumber]]$from <- as.integer(corrections$newedgefrom1[rowNum])
        json$edges[[newedgenumber]]$to <- as.integer(corrections$newedgeto1[rowNum])
        if (strsplit(corrections$newedgetype1[rowNum], ' ')[[1]][1] == 'Role') {
          json$edges[[newedgenumber]]$type <- 'Role'
          json$edges[[newedgenumber]]$reltype_main_t0 <- strsplit(corrections$newedgetype1[rowNum], ' ')[[1]][2]
          json$edges[[newedgenumber]]$reltype_sub_t0 <- stri_flatten(strsplit(corrections$newedgetype1[rowNum], ' ')[[1]][-(1:2)], collapse = ' ')
          json$edges[[newedgenumber]] <- json$edges[[newedgenumber]][c(2:7)]
        } else {
          # If it's a dyad edge between two alters, add k_or_p_t0: perceived.
          if ((identical(corrections$newedgetype1[rowNum],"Dyad")) & (!identical(corrections$newedgefrom1[rowNum],"0"))) {
            json$edges[[newedgenumber]]$k_or_p_t0 <- "pereceived"
            # Remove the undesirable first item.
            json$edges[[newedgenumber]] <- json$edges[[newedgenumber]][c(2:6)]
          } else {
            # Remove the undesirable first item.
            json$edges[[newedgenumber]] <- json$edges[[newedgenumber]][c(2:5)]
          }
        }
      }
      # See comments on newedgeid1 above for explanation.
      if (nchar(corrections$newedgeid2[rowNum]) > 0) {
        newedgenumber <- newedgenumber + 1
        json$edges[newedgenumber] <- toJSON(c())
        suppressWarnings(json$edges[[newedgenumber]]$id <- as.integer(corrections$newedgeid2[rowNum]))
        json$edges[[newedgenumber]]$type <- corrections$newedgetype2[rowNum]
        json$edges[[newedgenumber]]$from <- as.integer(corrections$newedgefrom2[rowNum])
        json$edges[[newedgenumber]]$to <- as.integer(corrections$newedgeto2[rowNum])
        if ((identical(corrections$newedgetype2[rowNum],"Dyad")) & (!identical(corrections$newedgefrom2[rowNum],"0"))) {
          json$edges[[newedgenumber]]$k_or_p_t0 <- "pereceived"
          json$edges[[newedgenumber]] <- json$edges[[newedgenumber]][c(2:6)]
        } else {
          json$edges[[newedgenumber]] <- json$edges[[newedgenumber]][c(2:5)]
        }
      }
      # See comments on newedgeid1 above for explanation.
      if (nchar(corrections$newedgeid3[rowNum]) > 0) {
        newedgenumber <- newedgenumber + 1
        json$edges[newedgenumber] <- toJSON(c())
        suppressWarnings(json$edges[[newedgenumber]]$id <- as.integer(corrections$newedgeid3[rowNum]))
        json$edges[[newedgenumber]]$type <- corrections$newedgetype3[rowNum]
        json$edges[[newedgenumber]]$from <- as.integer(corrections$newedgefrom3[rowNum])
        json$edges[[newedgenumber]]$to <- as.integer(corrections$newedgeto3[rowNum])
        if ((identical(corrections$newedgetype3[rowNum],"Dyad")) & (!identical(corrections$newedgefrom3[rowNum],"0"))) {
          json$edges[[newedgenumber]]$k_or_p_t0 <- "pereceived"
          json$edges[[newedgenumber]] <- json$edges[[newedgenumber]][c(2:6)]
        } else {
          json$edges[[newedgenumber]] <- json$edges[[newedgenumber]][c(2:5)]
        }
      }
      # See comments on newedgeid1 above for explanation.
      if (nchar(corrections$newedgeid4[rowNum]) > 0) {
        newedgenumber <- newedgenumber + 1
        json$edges[newedgenumber] <- toJSON(c())
        suppressWarnings(json$edges[[newedgenumber]]$id <- corrections$newedgeid4[rowNum])
        json$edges[[newedgenumber]]$type <- corrections$newedgetype4[rowNum]
        json$edges[[newedgenumber]]$from <- corrections$newedgefrom4[rowNum]
        json$edges[[newedgenumber]]$to <- corrections$newedgeto4[rowNum]
        if ((identical(corrections$newedgetype4[rowNum],"Dyad")) & (!identical(corrections$newedgefrom4[rowNum],"0"))) {
          json$edges[[newedgenumber]]$k_or_p_t0 <- "pereceived"
          json$edges[[newedgenumber]] <- json$edges[[newedgenumber]][c(2:6)]
        } else {
          json$edges[[newedgenumber]] <- json$edges[[newedgenumber]][c(2:5)]
        }
      }
      # See comments on newedgeid1 above for explanation.
      if (nchar(corrections$newedgeid5[rowNum]) > 0) {
        newedgenumber <- newedgenumber + 1
        json$edges[newedgenumber] <- toJSON(c())
        suppressWarnings(json$edges[[newedgenumber]]$id <- as.integer(corrections$newedgeid5[rowNum]))
        json$edges[[newedgenumber]]$type <- corrections$newedgetype5[rowNum]
        json$edges[[newedgenumber]]$from <- as.integer(corrections$newedgefrom5[rowNum])
        json$edges[[newedgenumber]]$to <- as.integer(corrections$newedgeto5[rowNum])
        if ((identical(corrections$newedgetype5[rowNum],"Dyad")) & (!identical(corrections$newedgefrom5[rowNum],"0"))) {
          json$edges[[newedgenumber]]$k_or_p_t0 <- "perceived"
          json$edges[[newedgenumber]] <- json$edges[[newedgenumber]][c(2:6)]
        } else {
          json$edges[[newedgenumber]] <- json$edges[[newedgenumber]][c(2:5)]
        }
      }
    }

    ## We are done correcting non-date errors! ##
    ## Now, rewrite the date for every file. ##
    # Get the date from the eventTime for the 75th log event.
    # 75 is used because no real interview could possibly go shorter than 75 events,
    # but you can be pretty certain that it happened the actual day of the interview.
    intdate <-  gsub("-","/",substr(json$log[[75]]$eventTime,1,10))
    # If the hour in eventTime is less than 5, it means that the GMT time has a date that is 1 greater than the date in CST.
    # So, we subtract one day from intdate.
    if (as.numeric(substr(json$log[[75]]$eventTime,12,13)) < 5) {
      intdate <- as.Date(intdate)
      intdate <- intdate - 1
      intdate <- gsub("-","/",intdate)
    }

    # If there aren't sessionParameters, it's an early V1. Write the date to the int_date_t0 variable.
    # Note that the visit number must be 1 for use below.
    if (is.null(json$sessionParameters)) {
      json$nodes[[1]]$int_date_t0 <- intdate
      visitnumber <- 1
    # Otherwise, the date goes in sessionParameter.
    # Take note of the visit number for use below.
    } else {
      json$sessionParameters$date <- intdate
      visitnumber <- json$nodes[[1]]$visit_number
    }

    ## Write the new file to Analysis Ready. ##
    jsonExport <- toJSON(json)
    # Remove slashes from date for use in file name.
    intdate <- gsub("/","",intdate)
    # Write the file with the filename based on the visit number, radar id, and interview date.
    write(jsonExport,file = paste0(folder.out,"Analysis Ready/V",visitnumber,"/",
                                   json$nodes[[1]]$radar_id,"_Network_Interview_V",visitnumber,"_",intdate,".json"))

    ## Add a tally to the number of processed files by visit number. ##
    if (visitnumber == 1) {
      numCopyFilesV1 <- numCopyFilesV1 + 1
    } else if (visitnumber == 2) {
      numCopyFilesV2 <- numCopyFilesV2 + 1
    } else if (visitnumber == 3) {
      numCopyFilesV3 <- numCopyFilesV3 + 1
    } else if (visitnumber == 4) {
      numCopyFilesV4 <- numCopyFilesV4 + 1
    }
  }

  ##### RESULTS #####
  writeLines(paste(" ",numCopyFilesV1,"V1s Processed."))
  writeLines(paste(" ",numCopyFilesV2,"V2s Processed."))
  writeLines(paste(" ",numCopyFilesV3,"V3s Processed."))
  writeLines(paste(" ",numCopyFilesV4,"V4s Processed."))
  if (numSkipped > 0) {writeLines(paste(" ",numSkipped,"file(s) skipped."))}
}