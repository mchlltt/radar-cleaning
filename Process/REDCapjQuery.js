javascript:(
	function(e,a,g,h,f,c,b,d) {
		if(!(f=e.jQuery)||g>f.fn.jquery||h(f)){
			c=a.createElement("script");
			c.type="text/javascript";
			c.src="https://ajax.googleapis.com/ajax/libs/jquery/"+g+"/jquery.min.js";
			c.onload=c.onreadystatechange=function(){
				if(!b&&(!(d=this.readyState)||d=="loaded"||d=="complete")) {
					h((f=e.jQuery).noConflict(1),b=1);
					f(c).remove();
				}
			};
			a.documentElement.childNodes[0].appendChild(c);
		}
	})
(window,document,"1.3.2",function($,L) {
	console.log('');
	var options = $('#record_select3').children();
	var firstRecord = options.length - 200;
	var idList = [];
	for (var i = firstRecord;i < options.length;i++) {
		var text = options[i].text;
		var words = text.split(' ');
		var date = words[2];
		var id = words[4];
		var visit = words[5].split('')[1];
		idList.push(id + 0 + visit + ',' + date);
	}
	console.log(idList.join('\r\n'));
});