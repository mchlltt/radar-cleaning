# RADAR Network Data Management Protocols

## Prerequisites

### Data access
1. Need REDCap RADAR Survey data access. (RADAR Data Manager)
2. Need access to private `radar-datapull`, `radar-database`, and `radar-weeklyUpdate` GitHub repositories. (RADAR Network Data Manager)
3. Need read/write/modify access to the `RADAR` folder on the shared drive. (ISGMH Research Project Coordinator)
4. Preferably, access to private `radar-protocol` and `radar-macronetwork` GitHub repositories. (RADAR Network Data Manager)
5. Preferably, REDCap RADAR Participant Tracking and/or RADAR Google Calendar access. (RADAR Data Manager and/or Project Director)

### Browser prep
1. Bookmark the sites included in `bookmarks.md`.
2. Create a bookmarklet for pulling REDCap IDs by following the directions in the README.md.

### Node prep
1. Install Node.js. (May require FSMIT)
2. Open a command prompt and type `node`. If the next line is just a `>`, type `.exit` to exit Node.
3. If you got an error, open the start menu and type `environment variables`, then select `Edit environmental variables for your account`.
4. Ensure that `PATH` is highlighted, then click `Edit...`.
5. If you already have content in the `PATH` variable, go to the end, then add a semicolon and then the path to the directory where Node was installed. e.g., `C:\users\userID\nodejs\`
6. If your `PATH` variable was empty, do the same as above, but without a semicolon.
7. Click `OK` on this dialog and then `OK` in the `Edit environmental variables for your account` box.
8. Repeat step #2. If you are still unsuccessful, contact IT. 

### R prep
1. Install R and/or RStudio. (May require FSMIT)
2. Run `requirements.R` in this directory to install R packages.
3. Clone the `radar-datapull` repository to your machine.
4. Run `buildRadarPackage.R` from that repository.

### Python prep
1. Install Python 2.7 and 3.5. (May require FSMIT)
2. Clone the `radar-database`, `radar-weeklyUpdate`, and `radar-macronetwork` repositories to your machine.
3. Install Python packages with `pip install -r python_requirements.txt` when in this directory.

### Neo4j prep
1. Install the Neo4j desktop client. (May require FSMIT)
2. Obtain the database password (RADAR Network Data Manager).

## Daily tasks

1. Open your REDCap survey bookmark, then log into REDCap.
2. Click on your REDCap ID pull bookmarklet, then open the console with `ctrl+shift+c`.
3. Find the first ID that is not already in `REDCapIDs.txt`.
4. Copy these IDs and paste them into `REDCapIDs.txt`.
5. Open RStudio or a command prompt.
6. If you opened RStudio, open `Process_NetworkFiles.R`. Source this file. By default, this is bound to `ctrl+shift+s`.
7. If you opened a command prompt, use `cd` to set your working directory to the `Scripts` folder. Type `R` to begin R on the command line. Type `source('Process_NetworkFiles.R').
8. Watch the output from running this file.
9. The `Transfer` script can signal issues with the files in the `Incoming` folder. If it indicates that any files were skipped, open `Incoming` and inspect its contents.
10. The `Clean` script generally does not signal any issues, but you should note the number of files processed and make sure nothing looks unusual.
11. The `Check` script exists explicitly to warn the user of potential data issues. It will compare the IDs in `REDCapIDs.txt` to the IDs on the files in the `Analysis Ready` folder, which is why it is important to update `REDCapIDS.txt` before starting this process.
12. Inspect all the issues noted by the `Check` script and fix what you can. This is the most likely place for you to catch that a RADAR ID or visit number has been entered incorrectly.
13. If the issue does not appear to be related to a data error, it may be that the file is actually missing. If you have taken reasonable measures to look for the file (e.g., checking `Incoming`), look up the interviewer who ran this interview on REDCap or the Google Calendar and reach out to the interviewer. The file has most often been forgotten on the tablet where the interview was conducted.
14. Repeat steps 4-6 until you do not see any issues come up on `Check` that you have not taken measures to fix yet.

## Weekly tasks

1. Run `PLoT ME Data Pull.R` in R. This is essential because any new app/venue/provider nodes are created based on this script's output.
2. Open the Neo4j desktop client and connect to the database.
3. Open a command prompt.
4. Change your working directory to the `radar-database` folder.
5. Run `python databasebuild.py`. Your alias for python may vary, so try `py` or `py3` if `python` does not work.
6. Enter the database password. Unless you have a reason or direction to do so, do not delete the database.
7. Wait for this script to run. It can take several minutes.
8. When it finishes running, verify the number of interviews added and ensure that it sounds like an accurate number of interviews to have been run since your last built the database.
9. Open RStudio or a command prompt.
10. Run `Misc/weeklyUpdate.R` or `misc_networkscripts.R` with `weeklyUpdate = TRUE`.
11. Open `Weekly Update.xlsx` in Misc/Weekly Update.
12. It should automatically refresh the data in the spreadsheet. Make sure this happened, generally by looking at the number of interviews in the last week.
13. If it did not update, refresh the data source.
14. Once it's updated, save the sheet as a pdf.
15. Combine this pdf with the plot pdf that was output by the R script.

## Monthly tasks

1. Open `configure_miscscripts.R` and set 
```
runAltGen <- TRUE
runIssue28 <- TRUE
runGenCodes <- TRUE
runPartnerNames <- TRUE
runUneditedChecks <- TRUE
```
2. Open the Neo4j desktop client and connect to the database.
3. Run `Misc_NetworkScripts.R` from the command line or RStudio.
4. Check the progress of the script intermittently until it finishes running.
5. Navigate to Misc/Validation Codes/jsonData/. Select all files inside this directory, then right click and, under `7-Zip` select `Add to archive...`.
6. You do not need to change any settings in this dialog except to set the password as the current RADAR account password.
7. The archive may take a few minutes to be created. When it's done, cut `jsonData.7z` from that folder and place it in `Network Data\Follow-Up Data`. Replace the existing copy of `jsonData.7z`.
8. Email Dan. Send him `valid_codes.csv` from Misc/Validation Codes/. Also inform him that `engagements_stats.csv` and `partner_names.csv` have been updated.
9. Check the output of the Issue 28 and Unedited Checks scripts. The output will either indicate that all is well or direct you on how to inspect potential data issues.

## Quarterly tasks

1. Go to Center on Halsted. 
2. Obtain the encrypted back-up flash-drive from the Project Director office.
3. Insert this flash-drive into your computer and enter the flash-drive password.
4. Replace the copies of `jsonData.7z` and `validcodes.csv` on the flash drive with their current versions from the shared drive.
5. Put the flash-drive back in its drawer.

## Ad hoc tasks

### Data corrections (general)

1. When you learn about a network data error, open `Data Error Log.xlsx` which is saved in `RADAR/Documents/Network Working Group/Documents`.
2. Create a new entry. Fill out as much information as you know about the error.
3. Once you know how the error will be corrected, include this information in the Data Error Log.
4. To create a correction, open a command prompt.
5. Set your working directory to Scripts/Corrections/.
6. Run `npm start` to start the script then select `Create corrections`.
7. Create the correction by following the prompts in the program.
8. If you want to view or delete other corrections, choose `View corrections` when you run the script.
9. If you're done with the script but haven't been given the option to quit, hit `control+C` to halt the script.
10. If the error occurred within the past 5 days, rerun the process scripts as usual. 
11. If it happened longer ago than that, open `configure_processscripts` and either increase `daysBeforeToday` to be longer ago than when the error occurred, or just set `all` to true, then run the process scripts. 
12. Find the file in `Analysis Ready` and verify that the correction was successfully made. Please note that the change will not apply to the data in the `log` portion of the JSON file. It will only be written in the nodes, edges, and/or session parameters.
13. If you changed `all` or `daysBeforeToday`, change them back to their default values once you verified that you were successful in correcting the issue.
14. If the change was to a RADAR ID, date, or visit number, or was removing an interview from analysis, you will need to go into `Analysis Ready` and remove the incorrect version of the data. For instance, if you changed the visit number on 2000's V2 to V3, you need to go into `Analysis Ready\V2` and delete the offending file.
15. For other changes, which would not affect the file name or location, the incorrect file will be overwritten and you do not need to delete the old version.

### Data corrections (renumber/offset)

With most network data errors, it is relatively clear what correction needs to be made to the data. Most often, a particular value needs to be changed, added, or removed. However, one case where it is considerably more complicated is when nodes need to be renumbered. This can become necessary when interview data is not collected and imported in a properly linear fashion. It is most often necessitated when a participant has a follow-up network interview run as a baseline network interview. Supposing a participant had named 10 alters at their first visit, alter IDs 1-10 would correspond to those 10 people. If the baseline data is loaded correctly at the next visit, new alters will be created starting with an ID of 11. However, if the baseline data is not loaded and the participant has another baseline-style network interview, they could perhaps name 12 alters, who would have IDs 1-12. When these two interviews are loaded into Neo4j, it would appear that the alters with the same alter IDs are the same people, but they may not be. Thus, before putting the data in the database, we want to go back and increment the alter IDs for the second set of 1-12. It is possible that some of the same people are in those two sets, but it's not worth the effort to try to identify who is who. Instead, we want to just assume that there is no overlap between the two groups. Thus, we would want to take every alter node ID in that second interview and, starting at 1, increment the ID by 10, making them 11-22. We cannot know that just from looking at 2nd interview. We had to look at the prior interview to see which was the first available/open node ID.

To put it more succinctly, if there is an situation wherein the same radar ID + alter ID combination may refer to two different people, you need to keep the two sets from overlapping by making one set's IDs start after the other's. In these cases, you will need to run the script for adding corrections (see steps 4-7 above), select 'renumber nodes', and input 1) the first node ID that should have its ID increased (in most cases, this is `1`),  and 2) how much each node ID should be increased by. This should be how many node IDs are already used up in previous interviews. If the ego already had 20 alters with IDs 1-20, the next alter should start at 21, so the 'offset' should be `20`.

### RADAR Interviewer Departure

When an interviewer leaves the project, their name should be added to `formerInts` in `configure_miscscripts.R`. This will remove them from the output for `interviewerStats.xlsx`.

### RADAR Interviewer Arrival

When a new interviewer joins the project, their name/ID should be added to `intIDsR.xlsx` file in the `Alter Generation Stats` folder. This will add them to the output for `interviewerStats.xlsx`.

Additionally, all new interviewers should receive network interview training as outlined in the Network Interviewer Guide.

### rsw888 Password Change

The password on the RADAR NetID is changed regularly. When it is changed, a few things need to be done to ensure that the same password is used across the resources that interviewers access. Making these updates in a timely manner is essential, as inconsistencies cause a large amount of stress and confusion for interviewers. 

##### jsonData.7z password

1. The first thing that needs to be changed is the `jsonData.7z` password.
2. You cannot change the password on an existing 7 Zip archive, so you will need to recreate it.
3. This requires you to have a folder full of all the files you will need to compress.
4. The simplest and most foolproof way to accomplish this is to run `Generate_Codes.R` and follow the standard procedure to create jsonData.7z fresh.
5. When you create the archive, make sure to set the new password.

##### BitLocker password

1. The second thing that needs to be changed is the BitLocker Encryption password on the two older tablets used for network interviews. 
2. These tablets are named "Rogue" and "Jubilee", which is what the COH team will know them as.
3. One or both of these tablets will be at Center on Halsted. One of them may be downtown for study visits held downtown.
4. Finding a time/opportunity to access these tablets is the most difficult part of this process.
5. Once you have access to each tablet, log into it as `rsw888`.
6. Open a Windows Explorer window.
7. Find the `C:/` drive in the left-hand column of the window.
8. Right-click the `C:/` drive label.
9. Click `Change BitLocker Password` in the menu that opens.
10. Change the password to the new `rsw888` password.
