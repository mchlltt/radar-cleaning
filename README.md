# RADAR Cleaning
R cleaning scripts used for network data from Northwestern University's RADAR Project. The primary purpose of this repository is to provide version control for a body of scripts that have previously been managed with filename changes. However, some additional information and context is provided for both potential users of the scripts and individuals curious about the scripts used for this data.

## Prerequisites
- R
- Neo4j (select scripts)

## Getting started
- Clone this repository to your machine by running `git clone <repo-url>`.
- Replace the placeholder folders with actual data and paths. Synthetic data/examples yet to come.
- If you are involved in the RADAR Project, please request `configure_networkscripts.txt`, `REDCapIDs.txt`, and `corrections.xlsx` from Pat Janulis.
- If you want to run all three of the core cleaning scripts, run `Process_NetworkFiles.R`.
- If you want to run any of the scripts individually, you can find them in the `Process/` directory.

## Regarding `corrections.xlsx`
- A dummy file showing the current headers used in this file is included. However, a project is currently underway to move away from tracking corrections in spreadsheet format, so this is included mostly as context for `2_Clean_NetworkFiles.R`.
- A sample `corrections.json` file will be included once this transition is completed.
- You can view the project to change how corrections are tracked at https://github.com/mchlltt/inquirer-corrections.

## Regarding `REDCapIDPull.js`
This file is the code for a bookmarklet pulls survey dates and participant IDs from REDCap ([Research Electronic Data Capture](https://catalyst.harvard.edu/services/redcap/)). If you have access to RADAR Survey data in REDCap, you can use this script by taking the following steps.
- Create a new bookmark in your browser.
- Set the title of the bookmark to 'REDCap ID Pull' or something else that you will understand.
- Copy the text in `REDCapIDPull.js`.
- Paste the contents of REDCapIDPull.js into the URL field of the new bookmark.
- Click this bookmark when you are on the RADAR Survey/Demographics page.
- Open your browser's developer tools. In Chrome, you can do this by right-clicking the page and selecting `Inspect Element` or by hitting 'Control-Shift-C' or 'Command-Shift-C'.
- If you are not already there, navigate to the 'Console' tab of the developer tools.
- Refer to your copy of `REDCapIds.txt` and identify the latest included ID.
- Copy from your console output beginning at the first new ID.
- Paste into `REDCapIds.txt`.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details 

## Authors
Mich Elliott - [mchlltt](http://github.com/mchlltt)
Patrick Janulis - [pfsj](http://github.com/pfsj)

## Acknowledgements
My time working on this project is funded by the NIH via Northwestern University's [Institute for Sexual and Gender Minority Health and Wellbeing](http://isgmh.northwestern.edu/). Visit the RADAR Project's [DokuWiki Codebook](http://codebook.netcanvas-r.com/doku.php?id=radar:start) if you are interested in the study collecting this data.
