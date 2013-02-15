// This is a test harness for your module
// You should do something interesting in this harness 
// to test out the module and to provide instructions 
// to users on how to use it by example.


// open a single window
var win = Ti.UI.createWindow({
	backgroundColor:'white'
});
var label = Ti.UI.createLabel();
win.add(label);
win.open();

var TwitterRequest = require('com.obscure.twitterreq');
Ti.API.info("module is => " + TwitterRequest);

/*
TwitterRequest.requestAccountInformation(function(e) {
  label.text = JSON.stringify(e);
});
*/

TwitterRequest.requestReverseAuthToken('paulegli', 'RgIGbmLM8X40Y5iXGzYqA', 'qn7Trco1rbsn5kndTZR8YwGm1PcNs0805Pgji2nD5E', function(e) {
  label.text = JSON.stringify(e);
});