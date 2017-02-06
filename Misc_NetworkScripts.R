# Run the various monthly/ad-hoc scripts from one script.
# Adjust settings in any of the scripts by editing
# configure_miscscripts.txt, located in this folder.
# You can also always run any of these scripts individually by opening the script file.

# Read settings file.
# Try to read from this directory. If it's not here, try the next directory up.
tryCatch({
  con <- file("configure_miscscripts.txt")
  source(con)
}, error = function(e) {
  con <- file("../configure_miscscripts.txt")
  source(con)
}, finally = {
  close(con)
})

# List R script files in this folder.
filenames = list.files("./", pattern = "*.R", full.names = TRUE)

# Select appropriate scripts. Use grep to allow for changing filename dates.
altGen <- grep("Alt Gen Stats", filenames, value = TRUE)
issue28 <- grep("Issue 28", filenames, value = TRUE)
genCodes <- grep("Generate Codes", filenames, value = TRUE)
partnerNames <- grep("Partner Names", filenames, value = TRUE)
uneditedChecks <- grep("Unedited Checks", filenames, value = TRUE)
weeklyUpdate <- grep("weeklyUpdate", filenames, value = TRUE)
PLoTMEPull <- grep("PLoT", filenames, value = TRUE)

# Check that you aren't missing any scripts and that you don't have multiple versions of a single script.
# If the check passes, we can now consider each script individually.
if (length(altGen) == 1 &
    length(issue28) == 1 &
    length(genCodes) == 1 &
    length(partnerNames) == 1 &
    length(uneditedChecks) == 1 &
    length(weeklyUpdate) == 1 &
    length(PLoTMEPull == 1)) {
  # Each script has a boolean variable at the beginning of configure_miscscripts.txt that determines whether the script will be run.
  # If you want a script to run, you must change the relevant variable to TRUE and vice versa if you would like them to not run.
  # NOTE: A few scripts require Neo4j. If you have these scripts' run variables set to TRUE,
  # you must be connected to Neo4j or else the entire script will fail on line 8.
  if (runAltGen) {
    writeLines("Alter Generation Stats:")
    source(altGen)
  } else {
    writeLines("Alter Generation Stats was not run.")
  }
  if (runIssue28) {
    writeLines("\nIssue 28:")
    source(issue28)
  } else {
    writeLines("\nIssue 28 was not run.")
  }
  if (runGenCodes) {
    writeLines("\nValidation Codes:")
    source(genCodes)
  } else {
    writeLines("\nValidation Codes was not run.")
  }
  if (runPartnerNames) {
    writeLines("\nPartner Names:")
    source(partnerNames)
  } else {
    writeLines("\nPartner Names was not run.")
  }
  if (runUneditedChecks) {
    writeLines("\nUnedited Checks:")
    source(uneditedChecks)
  } else {
    writeLines("\nUnedited Checks was not run.")
  }
  if (runWeeklyUpdate) {
    writeLines("\nWeekly Update:")
    source(weeklyUpdate)
  } else {
    writeLines("\nWeekly Update was not run.")
  }
  if (runPLoTME) {
    writeLines("\nPLoT ME Data Pull:")
    source(PLoTMEPull)
  } else {
    writeLines("\nPLoT ME Data Pull was not run.")
  }
  # Otherwise, warn the user and stop the script.
} else {
  writeLines(
    "You don't have exactly one version of each script. Please make sure there is one of each and try again."
  )
}
