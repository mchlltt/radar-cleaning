// Bookmarklets disagree with comments, so this commented version exists for context but cannot be used in a bookmark.
/**
 * Pulls and prints IDs from a specific dropdown.
 * @param {number} numberRecords - The number of records you want to pull.
 */

// We're defining a function called `getIDs` that takes a parameter that determines how many records to pull.
function getIDs(numberRecords) {
    // First, log a blank line to the console, so that there's a gap before the output starts.
    console.log('');
    // Get all the options thare are under 'record_select3', which is the dropdown of completed surveys.
    var options = document.getElementById('record_select3').childNodes;
    // We are subtracting the number of records we want from the total number of records.
    // This gives us the index of the first record we'll want to consider if we want the X most recent records.
    var firstRecord = options.length - numberRecords;
    // Initialize an empty array that we will push IDs to.
    var idList = [];
    // Starting with the first record we want to consider, step through each record until we get to the end.
    for (var i = firstRecord; i < options.length - 1; i++) {
        // Pull the text of the option. Written two ways because of browser inconsistencies.
        var text = options[i].innerText || options[i].textContent;
        // Split the text on spaces.
        var words = text.split(' ');
        // The third item in that array should be the date.
        var date = words[2];
        // The ID is the 5th word in the array.
        var id = words[4];
        // Split the sixth word into its individual characters. The second character is the visit number.
        var visit = words[5].split('')[1];
        // The full ID we want is the RADAR ID plus a zero plus the visit number, then a comma and the date.
        idList.push(id + 0 + visit + ',' + date);
    }

    // Once you've collected the whole list, print it to the console with line breaks in between records.
    console.log(idList.join('\r\n'));
}

// Change this value if you want more or less records.
var recordCount = 200;

// Run the function we defined above with the recordCount parameter.
getIDs(recordCount);