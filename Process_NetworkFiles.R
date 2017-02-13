# Run the transfer, clean, and check scripts all at once!
# Adjust settings in any of the scripts by editing
# configure_networkscripts.txt, located in this folder.
# You can also always run any of these scripts individually by opening the script file.

# Run list.files on the Process folder.
filenames <- list.files(path = 'Process/', full.names = TRUE, pattern = '*.R')

# If you got results, you know you are in the root folder and can run the configuration script from there.
if (length(filenames) > 0) {
  con <- file("configure_networkscripts.txt")
  source(con)
  close(con)
# Otherwise, you must be one level down, so run these operations from that position in the file tree.
} else {
  filenames = list.files('../Process/', full.names = TRUE, pattern = '*.R')
  if (length(filenames) > 0) {
    con <- file("../configure_networkscripts.txt")
    source(con)
    close(con)
  } else {
    stop(paste0('Your working directory is ', getwd(), '. Please set it to the directory of this script.'))
  }
}

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
