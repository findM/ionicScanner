
/*
 * 简介：这是一个扫描插件，目前只有iOS平台
 * 作者：陈光临
 */


var exec = require('cordova/exec');

exports.scan = function(arg0, success, error) {
    exec(success, error, "bqScanner", "scan", [arg0]);
};
