<?php
/*
 * (c)2009 lists@nerdbynature.de
 * Display REMOTE_ADDR, HTTP_X_FORWARDED_FOR, HTTP_USER_AGENT of the client
 *
 */
$ip1 = $_SERVER['REMOTE_ADDR'];
$ip2 = $_SERVER['HTTP_X_FORWARDED_FOR'];
$host1 = isset($ip1) ? gethostbyaddr($ip1) : "";
$host2 = isset($ip2) ? gethostbyaddr($ip2) : "";
$ua = $_SERVER['HTTP_USER_AGENT'];

echo "<?xml version=\"1.0\"?>
<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"
    \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\">
<head>
	<title></title>
	<meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\" />
</head>
<body>
<table summary=\"IPv4\" border=\"1\">
<tr><td>REMOTE_ADDR</td><td>$ip1 ($host1)</td></tr>
<tr><td>HTTP_X_FORWARDED_FOR</td><td>$ip2 ($host2)</td></tr>
<tr><td>HTTP_USER_AGENT</td><td>$ua</td></tr>
</table></body></html>\n";

/* TODO: implement plain-text output
$ip = isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : $_SERVER['HTTP_X_FORWARDED_FOR'];
$host = gethostbyaddr($ip);
$ua = $_SERVER['HTTP_USER_AGENT'];
 */
?>
