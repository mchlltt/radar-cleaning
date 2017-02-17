javascript:function getIDs(numberRecords) {
    console.log('');
    var options = document.getElementById('record_select3').childNodes;
    var firstRecord = options.length - numberRecords;
    var idList = [];
    for (var i = firstRecord; i < options.length - 1; i++) {
        var text = options[i].innerText || options[i].textContent;
        var words = text.split(' ');
        var date = words[2];
        var id = words[4];
        var visit = words[5].split('')[1];
        idList.push(id + 0 + visit + ',' + date);
    }

    console.log(idList.join('\r\n'));
}

var recordCount = 200;

getIDs(recordCount);