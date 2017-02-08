##### PURPOSE #####
## Pull PLoT ME Data for initial analysis.

##### LIBRARIES #####
# For converting lists to dataframes.
library(plyr)
# For substrings.
library(stringr)
# For reading JSON files.
library(rjson)
# For writing to xlsx. Requiring library dependencies explicitly to avoid messages.
library(rJava)
library(xlsxjars)
library(xlsx)

# Read settings file. Try multiple paths to the settings file.
tryCatch({
  source("configure_miscscripts.txt")
}, error = function(e) {
  return(source("../configure_miscscripts.txt"))
}, warning = function(e) {
  return(source("../configure_miscscripts.txt"))
})

##### PULL FROM JSON FILES #####

files <- c()
folders <-
  list.dirs(path = paste0(folder.in.plotme), recursive = FALSE)
# For folders in Analysis Ready,
for (i in 1:length(folders)) {
  # Select the V# folders.
  if (identical(str_sub(folders[i], -2, -2), "V")) {
    # We don't run PLoT ME at V1s, though, so we can skip those.
    if (as.integer(str_sub(folders[i], -1, -1)) != 1) {
      # Add the files in these folders to files.
      files <-
        append(
          files,
          list.files(
            path = folders[i],
            pattern = "*.json",
            recursive = FALSE,
            full.names = TRUE
          )
        )
    }
  }
}

fileList <- c()
for (i in 1:length(files)) {
  # Get the date from the file name and convert it to date.
  # Select only those files that took place since the beginning of September,
  # Since that's about when we started PLoT ME.
  if (as.Date(paste0(
    str_sub(files[i], -13, -10),
    str_sub(files[i], -9, -8),
    str_sub(files[i], -7, -6)
  ), "%Y%m%d") > as.Date("2016-09-01")) {
    fileList <- append(fileList, files[i])
  }
}


## Pull all PLoT ME edges + service provider nodes

# Initialize these lists of lists.
list.venues <- list()
list.apps <- list()
list.services.edges <- list()
list.services.nodes <- list()
list.testing <- list()
list.prevention <- list()
list.treatment <- list()

for (i in 1:length(fileList)) {
  # Reset lists and counter variables.
  venueEdges <- list()
  appEdges <- list()
  serviceEdges <- list()
  serviceNodes <- list()
  testingEdges <- list()
  preventionEdges <- list()
  treatmentEdges <- list()
  countVenues <- 0
  countApps <- 0
  countServices <- 0
  countServiceNodes <- 0
  countTesting <- 0
  countPrevention <- 0
  countTreatment <- 0

  # Read JSON file and get radarid and visitnumber from it.
  json <- fromJSON(file = fileList[i])
  radarid <- as.character(json$nodes[[1]]$radar_id)
  visitnumber <- json$nodes[[1]]$visit_number

  # For each venue edge, add the edge to venueEdges.
  for (n in 1:length(json$edges)) {
    if (json$edges[[n]]$type == "Venue") {
      countVenues <- countVenues + 1
      venueEdges[[countVenues]] <- json$edges[[n]]
    }
  }

  # For each app edge, add the edge to appEdges.
  for (n in 1:length(json$edges)) {
    if (json$edges[[n]]$type == "App") {
      countApps <- countApps + 1
      appEdges[[countApps]] <- json$edges[[n]]
    }
  }

  # For each provider edge, add the edge to serviceEdges.
  for (n in 1:length(json$edges)) {
    if (json$edges[[n]]$type == "HIVService") {
      countServices <- countServices + 1
      serviceEdges[[countServices]] <- json$edges[[n]]
    }
  }

  # For each provider node, add the node to serviceNodes.
  for (n in 1:length(json$nodes)) {
    if (json$nodes[[n]]$type_t0 == "HIVService") {
      countServiceNodes <- countServiceNodes + 1
      serviceNodes[[countServiceNodes]] <- json$nodes[[n]]
    }
  }

  # For each HadTesting edge, add the edge to testingEdges.
  # For these edges, empty details arrays must be nulled out to avoid errors.
  for (n in 1:length(json$edges)) {
    if (json$edges[[n]]$type == "HadTesting") {
      countTesting <- countTesting + 1
      testingEdges[[countTesting]] <- json$edges[[n]]
      if (length(json$edges[[n]]$details) == 0) {
        testingEdges[[countTesting]]$details <- NULL
      }
    }
  }

  # For each HadPrevention edge, add the edge to preventionEdges.
  # For these edges, empty details arrays must be nulled out to avoid errors.
  for (n in 1:length(json$edges)) {
    if (json$edges[[n]]$type == "HadPrevention") {
      countPrevention <- countPrevention + 1
      preventionEdges[[countPrevention]] <- json$edges[[n]]
      if (length(json$edges[[n]]$details) == 0) {
        preventionEdges[[countPrevention]]$details <- NULL
      }
    }
  }

  # For each HadTreatment edge, add the edge to treatmentEdges.
  # For these edges, empty details arrays must be nulled out to avoid errors.
  for (n in 1:length(json$edges)) {
    if (json$edges[[n]]$type == "HadTreatment") {
      countTreatment <- countTreatment + 1
      treatmentEdges[[countTreatment]] <- json$edges[[n]]
      if (length(json$edges[[n]]$details) == 0) {
        treatmentEdges[[countTreatment]]$details <- NULL
      }
    }
  }

  # If there were any of a thing, add those edges or nodes to the correct df list, along with the radarid and visitnumber.
  if (countVenues > 0) {
    list.venues[[i]] <-
      ldply(venueEdges, data.frame, stringsAsFactors = FALSE)
    list.venues[[i]]$radarid <- radarid
    list.venues[[i]]$visitnumber <- visitnumber
  }
  if (countApps > 0) {
    list.apps[[i]] <-
      ldply(appEdges, data.frame, stringsAsFactors = FALSE)
    list.apps[[i]]$radarid <- radarid
    list.apps[[i]]$visitnumber <- visitnumber
  }
  if (countServices > 0) {
    list.services.edges[[i]] <-
      ldply(serviceEdges, data.frame, stringsAsFactors = FALSE)
    list.services.edges[[i]]$radarid <- radarid
    list.services.edges[[i]]$visitnumber <- visitnumber
  }
  if (countServiceNodes > 0) {
    list.services.nodes[[i]] <-
      ldply(serviceNodes, data.frame, stringsAsFactors = FALSE)
    list.services.nodes[[i]]$radarid <- radarid
    list.services.nodes[[i]]$visitnumber <- visitnumber
  }
  if (countTesting > 0) {
    list.testing[[i]] <-
      ldply(testingEdges, data.frame, stringsAsFactors = FALSE)
    list.testing[[i]]$radarid <- radarid
    list.testing[[i]]$visitnumber <- visitnumber
  }
  if (countPrevention > 0) {
    list.prevention[[i]] <-
      ldply(preventionEdges, data.frame, stringsAsFactors = FALSE)
    list.prevention[[i]]$radarid <- radarid
    list.prevention[[i]]$visitnumber <- visitnumber
  }
  if (countTreatment > 0) {
    list.treatment[[i]] <-
      ldply(treatmentEdges, data.frame, stringsAsFactors = FALSE)
    list.treatment[[i]]$radarid <- radarid
    list.treatment[[i]]$visitnumber <- visitnumber
  }
}

# Turn all the lists of lists into dataframes.
venueData <- ldply(list.venues, data.frame, stringsAsFactors = FALSE)
appData <- ldply(list.apps, stringsAsFactors = FALSE)
serviceEdgeData <-
  ldply(list.services.edges, data.frame, stringsAsFactors = FALSE)
serviceNodeData <-
  ldply(list.services.nodes, data.frame, stringsAsFactors = FALSE)
testingData <-
  ldply(list.testing, data.frame, stringsAsFactors = FALSE)
preventionData <-
  ldply(list.prevention, data.frame, stringsAsFactors = FALSE)
treatmentData <-
  ldply(list.treatment, data.frame, stringsAsFactors = FALSE)

# Add a bunch of columns so that merging will be easier/prettier.
venueData$ag_t0 <- NA
venueData$app_name_t0 <- NA
venueData$app_freq_t0 <- NA
venueData$visited <- NA
venueData$provider_awareness <- NA
venueData$sg_t0 <- NA
venueData$visit_frequency <- NA
venueData$welcoming <- NA
venueData$name <- NA
venueData$reason_not_visited <- NA
venueData$details <- NA
venueData$to <- NA
appData$to <- NA
appData$id <- NA
testingData$id <- NA
preventionData$id <- NA
treatmentData$id <- NA

# These edge IDs get in the way of matching provider nodes and edges.
serviceEdgeData$id <- NULL
# This column isn't useful, so we don't want to merge it in with serviceEdgeData.
serviceNodeData$type_t0 <- NULL

# Merge service providers edges and nodes by the node 'id'/edge 'to' value.
serviceData <-
  merge.data.frame(
    serviceNodeData,
    serviceEdgeData,
    by.x = c("id", "radarid", "visitnumber"),
    by.y = c("to", "radarid", "visitnumber"),
    all = TRUE
  )

# Incrementally merge all these dataframes together.
allData1 <- merge.data.frame(venueData, appData, all = TRUE)
allData2 <- merge.data.frame(allData1, serviceData, all = TRUE)
allData3 <- merge.data.frame(allData2, testingData, all = TRUE)
allData4 <- merge.data.frame(allData3, preventionData, all = TRUE)
allData <- merge.data.frame(allData4, treatmentData, all = TRUE)

# Remove the from variable from all the data at once. It's always 0.
allData$from <- NULL

##### EXPORT #####
# Order by the edge ID.
allData <- allData[order(allData$id), ]
# Then by the RADAR ID.
allData <- allData[order(allData$radarid), ]

# Trim white space from both sides of all venue/provider/app names.
venueData$venue_name_t0 <- trimws(venueData$venue_name_t0)
appData$app_name_t0 <- trimws(appData$app_name_t0)
serviceData$name <- trimws(serviceData$name)

allVenues <-
  venueData[which(!duplicated(venueData$venue_name_t0)), c("venue_name_t0", "venue_location_p_t0")]
allApps <- c(na.omit(unique(allData$app_name_t0)))
allProviders <-
  unique.data.frame(data.frame(serviceData$name, stringsAsFactors = FALSE))
providerData <-
  read.csv(paste0(folder.out.plotme, "providerData.csv"),
           stringsAsFactors = FALSE)
providers = merge.data.frame(
  allProviders,
  providerData,
  by.x = "serviceData.name",
  by.y = "Abbreviated.Name",
  all.x = TRUE,
  all.y = FALSE
)
providers = providers[, c(1, 5)]

write.csv(
  allData,
  file = paste0(folder.out.plotme, "plotmedata_", Sys.Date(), ".csv"),
  row.names = FALSE,
  na = ""
)
write.xlsx(allVenues,
           file = paste0(folder.out.plotme, "venues.xlsx"),
           showNA = FALSE)
write.xlsx(allApps,
           file = paste0(folder.out.plotme, "apps.xlsx"),
           showNA = FALSE)
write.xlsx(
  providers,
  file = paste0(folder.out.plotme, "providers.xlsx"),
  showNA = FALSE
)

writeLines(paste0(
  "  PLoT ME data written to ",
  folder.out.plotme,
  "plotmedata_",
  Sys.Date(),
  ".csv"
))