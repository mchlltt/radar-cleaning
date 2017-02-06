# Run the transfer, clean, and check scripts all at once!
# Adjust settings in any of the scripts by editing
# configure_networkscripts.txt, located in this folder.
# You can also always run any of these scripts individually by opening the script file.

# Read settings file.
# It's not guaranteed whether the working directory is Scripts or Scripts/Process, so try both paths to settings.
tryCatch({
  con <- file("configure_networkscripts.txt")
  source(con)
}, error = function() {
  con <- file("../configure_networkscripts.txt")
  source(con)
}, finally = {
  close(con)
})

# List R script files in the process scripts folder.
filenames = list.files("Process/",pattern = "*.R",full.names = TRUE)

# Select appropriate scripts. Use grep to allow for changing filename dates.
trans <- grep("Transfer_Network", filenames, value = TRUE)
clean <- grep("Clean_Network", filenames, value = TRUE)
check <- grep("Check_Network", filenames, value = TRUE)

# Check that you aren't missing any scripts and that you don't have multiple versions of a single script.
# If the check passes, source each script.
if (length(trans) == 1 &
    length(clean) == 1 &
    length(check) == 1) {
  writeLines("Transfer:")
  source(trans)
  writeLines("\nClean:")
  source(clean)
  writeLines("\nCheck:")
  source(check)
  # Otherwise, warn the user and stop the script.
} else {
  writeLines(
    "You don't have exactly one version of each script. Please make sure there is one of each and try again."
  )
}
