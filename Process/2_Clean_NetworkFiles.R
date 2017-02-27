##### PURPOSE #####
## This script reads JSON files in the Raw folders and cleans them for analysis.
## Errors are recorded in the Error Log and processed via corrections.json.
## Dates are amended in all files to correct errors and to uniformize formatting.
## A corrected version of each JSON file is then saved in the Analysis Ready folders.

##### LIBRARIES & SET-UP #####
## Libraries
# For substrings.
library(stringr)
# For reading JSON files.
library(rjson)
# For writing JSON files with pretty-printing.
# warn.conflicts = FALSE avoids warnings about json/jsonlite overlapping function names.
# Those overlaps aren't an issue becaues we specify which package's function to use each time.
library(jsonlite, warn.conflicts = FALSE)

# Function for finding the index of an edge or node.
findIndex <- function(my.list, my.id, all.matches = FALSE) {
  indices <- c()
  # Step through node or edge list.
  for (i in 1:length(my.list)) {
    # Once you find a node or edge with the correct ID,
    if (my.list[[i]]$id == my.id) {
      # If we want all the matching indices, collect them and return the list once you have stepped through the entire list.
      if (all.matches) {
        indices <- c(indices, i)
      # If we just want the first occurence, return it immediately.
      } else {
        # return its index.
        return(i)
      }
    }
  }
  return(indices)
}

# Function for getting new ID number for new nodes and edges.
getNewID <- function(my.list) {
  ids <- c()
  # Step through node or edge list.
  for (i in 1:length(my.list)) {
    # Add all IDs to a list.
    ids <- c(ids, my.list[[i]]$id)
  }

  # Sort that list descending.
  ids <- sort(ids, decreasing = TRUE)

  # Return the highest value plus 1.
  return(ids[1] + 1)
}

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

# Read the corrections.json file.
corrections <- rjson::fromJSON(file = correctionsPath)

##### SELECT FILES TO PROCESS #####
## List all raw files. ##

files <- c()
folders <- list.dirs(path = paste0(folder.in), recursive = FALSE)
# For folders in Raw,
for (i in 1:length(folders)) {
  # If it is a V# folder,
  if (identical(str_sub(folders[i], -2, -2), 'V')) {
    # Add all the filenames in the folder to a list.
    files <-
      append(
        files,
        list.files(
          path = folders[i],
          pattern = '*.json',
          recursive = FALSE,
          full.names = TRUE
        )
      )
  }
}

# Determines which files will be cleaned.
if (all) {
  # If you want to reclean all files, change all to TRUE.
  writeLines(
    '  Processing ALL files. (If this isn\'t what you wanted, hit CTRL+C to abort,
    then set `all` to FALSE in the settings file.)'
  )
} else {
  # By default, today and the prior 4 days files are cleaned. To change this number, change daysBeforeToday in the settings file.
  # daysBeforeToday = 0 will process today's files only.
  writeLines(
    paste(
      '  Processing today\'s and the prior',
      daysBeforeToday,
      'days\' network interview files.'
    )
  )
  files <- files[which(Sys.Date() - as.Date(str_sub(files, -13, -6), '%Y%m%d') <= daysBeforeToday)]
}

##### PROCESS FILES #####
## Initialize files processed and skipped counters.
numCopyFilesV1 <- 0
numCopyFilesV2 <- 0
numCopyFilesV3 <- 0
numCopyFilesV4 <- 0
numCopyFilesV5 <- 0
numSkipped <- 0

if (length(files) == 0) {
  writeLines('\n  No files found to clean! Please set all to TRUE or increase daysBeforeToday.')
} else {
  ## For each file,
  for (i in 1:length(files)) {
    # Import from JSON.
    json <- rjson::fromJSON(file = files[i])
    # [Re]set skip variable to FALSE.
    skip <- FALSE

    ## If the filename is a key of corrections, it needs to be corrected.
    # List indexing in R is a mess, but this means that the filename is a key in `corrections`.
    # Literally: There exists a value for this key in `corrections`.
    if (!is.null(corrections[files[i]][[1]])) {
      # Grab the list of corrections.
      this.corrections <- corrections[files[i]][[1]]

      # Iterate through the list, switching based on the correction type.
      for (j in 1:length(this.corrections)) {
        # Pull corrections and ID. Either or both may be NULL, depending on the correction type.
        this.data <- this.corrections[[j]]$correctData
        this.vars <- names(this.corrections[[j]]$correctData)
        this.id <- this.corrections[[j]]$id

        # This is a neater `if` statement with logic that branches based on the value of the first argument.
        # Execute the argument of this switch function based on the type of the correction.
        switch(
          this.corrections[[j]]$type,
          'Remove interview from analysis' = {
            # This will block the interview from being copied.
            skip <- TRUE
          },
          'Interviewer ID update' = {
            # Overwrite interviewer ID.
            json$sessionParameters$interviewerID <- this.data$interviewerID
          },
          'Node update' = {
            # Grab the index or indices for this node id.
            index <- findIndex(json$nodes, this.id, all.matches = TRUE)

            # Iterate through the indices.
            for (m in 1:length(index)) {
              # Set each variable. If a deletion is indicated, remove the variable.
              for (k in 1:length(this.data)) {
                if (this.data[k] == '[Delete]') {
                  json$nodes[[index[m]]][this.vars[k]] <- NULL
                } else {
                  json$nodes[[index[m]]][this.vars[k]] <- this.data[k]
                }
              }
            }
          },
          'Edge update' = {
            # Grab the index or indices for this edge id.
            index <- findIndex(json$edges, this.id, all.matches = TRUE)

            # Iterate through the indices.
            for (m in 1:length(index)) {
              # Set each variable. If a deletion is indicated, remove the variable.
              for (k in 1:length(this.data)) {
                if (this.data[k] == '[Delete]') {
                  json$edges[[index[m]]][this.vars[k]] <- NULL
                } else {
                  json$edges[[index[m]]][this.vars[k]] <- this.data[k]
                }
              }
            }
          },
          'Node deletion' = {
            # Set `toDelete` to an empty vector.
            toDelete <- c()
            # Get the IDs of nodes to delete
            ids <- this.data$ids

            # Mark the first node found with each ID for deletion.
            # Only mark the first instance because we could be getting rid of duplicates. See Data Error Log #41 and #50.
            for (k in 1:length(ids)) {
              toDelete <- c(toDelete, findIndex(json$nodes, ids[k]))
            }

            # Delete nodes based on the indices gathered above.
            json$nodes[toDelete] <- NULL
          },
          'Edge deletion' = {
            # Set `toDelete` to an empty vector.
            toDelete <- c()
            # Get the IDs of edges to delete
            ids <- this.data$ids

            # Mark the first edge found with each ID for deletion.
            # Only mark the first instance because we could be getting rid of duplicates. See Data Error Log #41 and #50.
            for (k in 1:length(ids)) {
              toDelete <- c(toDelete, findIndex(json$edges, ids[k]))
            }

            # Delete edges based on the indices gathered above.
            json$edges[toDelete] <- NULL
          },
          'Node creation' = {
            # The node's index will be one greater than the current max.
            nodeIndex <- length(json$nodes) + 1

            # Initialize the node as a list.
            json$nodes[[nodeIndex]] <- list()
            # Assign its id.
            json$nodes[[nodeIndex]]$id <- getNewID(json$nodes)

            # Assign any variables.
            for (k in 1:length(this.data)) {
              json$nodes[[nodeIndex]][this.vars[k]] <- this.data[k]
            }
          },
          'Edge creation' = {
            # The edge's index will be one greater than the current max.
            edgeIndex <- length(json$edges) + 1

            # Initialize the edge as a list.
            json$edges[[edgeIndex]] <- list()
            # Assign its id.
            json$edges[[edgeIndex]]$id <- getNewID(json$edges)

            # Assign any variables.
            for (k in 1:length(this.data)) {
              json$edges[[edgeIndex]][this.vars[k]] <- this.data[k]
            }
          },
          'Renumber nodes/edges' = {
            # Get start and offset values.
            start <- as.integer(this.data$start)
            offset <- as.integer(this.data$offset)

            # Walk through nodes and edges, adjusting to/from values (edges) and ids (nodes).
            for (k in 1:length(json$edges)) {
              if (json$edges[[k]]$to >= start) {
                json$edges[[k]]$to <- json$edges[[k]]$to + offset
              }
              if (json$edges[[k]]$from >= start) {
                json$edges[[k]]$from <- json$edges[[k]]$from + offset
              }
            }

            for (k in 1:length(json$nodes)) {
              if (json$nodes[[k]]$id >= start) {
                json$nodes[[k]]$id <- json$nodes[[k]]$id + offset
              }
            }

            # Update reserved_ids. Raise its highest value by adding the offset.
            highestReservedID <- max(json$nodes[[1]]$reserved_ids)
            newHighestReservedID <- highestReservedID + offset
            json$nodes[[1]]$reserved_ids <- 0:newHighestReservedID
          }
        )
      }
    }

    ## We are done correcting non-date errors! Now, rewrite the date for every file. ##
    # Get the date from the eventTime for the 75th log event. 75 is used because no real interview could possibly go shorter than 75 events,
    # but you can be pretty certain that it happened the actual day of the interview.
    intdate <-  gsub('-', '/', substr(json$log[[75]]$eventTime, 1, 10))

    # If the hour in eventTime is less than 5, it means that the GMT time has a date that is 1 greater than the date in CST, so we subtract one day from intdate.
    if (as.numeric(substr(json$log[[75]]$eventTime, 12, 13)) < 5) {
      intdate <- as.Date(intdate)
      intdate <- intdate - 1
      intdate <- gsub('-', '/', intdate)
    }

    # If there aren't sessionParameters, we know it's an early V1. Write the date to the int_date_t0 variable.
    if (is.null(json$sessionParameters)) {
      json$nodes[[1]]$int_date_t0 <- intdate
      visitnumber <- 1
      # Otherwise, the date goes in sessionParameter. Store the visit number for use below.
    } else {
      json$sessionParameters$date <- intdate
      visitnumber <- json$nodes[[1]]$visit_number
    }

    ## Write the new file to Analysis Ready. ##
    jsonExport <-
      jsonlite::toJSON(json, pretty = 2, auto_unbox = TRUE, null = 'null', na = 'null')
    # Remove slashes from date for use in file name.
    intdate <- gsub('/', '', intdate)

    if (skip) {
      numSkipped <- numSkipped + 1
    } else {
      # Write the file with the filename based on the visit number, radar id, and interview date.
      write(
        jsonExport,
        file = paste0(
          folder.out,
          'Analysis Ready/V',
          visitnumber,
          '/',
          json$nodes[[1]]$radar_id,
          '_Network_Interview_V',
          visitnumber,
          '_',
          intdate,
          '.json'
        )
      )

      ## Add a tally to the number of processed files by visit number.
      if (visitnumber == 1) {
        numCopyFilesV1 <- numCopyFilesV1 + 1
      } else if (visitnumber == 2) {
        numCopyFilesV2 <- numCopyFilesV2 + 1
      } else if (visitnumber == 3) {
        numCopyFilesV3 <- numCopyFilesV3 + 1
      } else if (visitnumber == 4) {
        numCopyFilesV4 <- numCopyFilesV4 + 1
      } else if (visitnumber == 5) {
        numCopyFilesV5 <- numCopyFilesV5 + 1
      }
    }
  }


  ##### RESULTS #####
  writeLines(paste(' ', numCopyFilesV1, 'V1s Processed.'))
  writeLines(paste(' ', numCopyFilesV2, 'V2s Processed.'))
  writeLines(paste(' ', numCopyFilesV3, 'V3s Processed.'))
  writeLines(paste(' ', numCopyFilesV4, 'V4s Processed.'))
  writeLines(paste(' ', numCopyFilesV5, 'V5s Processed.'))
  if (numSkipped > 0) {
    writeLines(paste(' ', numSkipped, 'file(s) skipped.'))
  }
}
