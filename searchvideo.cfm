
<CFPARAM name="url.id" default="1">
<CFSWITCH expression="#url.id#">
	<CFCASE value="1"><CFSET linkfile = "iA5cnZNxxzM"><CFSET pagetitle="Online Registration: Login"></CFCASE>
	<CFCASE value="2"><CFSET linkfile = "sIEEnpxFpUM"><CFSET pagetitle="Online Registration: Class Search & Checkout"></CFCASE>
	<CFCASE value="3"><CFSET linkfile = "yrWIQ4NymkM"><CFSET pagetitle="Online Registration: Advanced Class Search"></CFCASE>
	<CFDEFAULTCASE><CFSET linkfile = "sIEEnpxFpUM"><CFSET pagetitle="Online Registration: Class Search & Checkout"></CFDEFAULTCASE>
</CFSWITCH>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title><CFOUTPUT>#pagetitle#</CFOUTPUT></title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body topmargin="0" leftmargin="0" marginheight="0">
<CFOUTPUT>
<object width="640" height="505"><param name="movie" value="http://www.youtube.com/v/#linkfile#&hl=en&fs=1&rel=0&autoplay=1"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="https://www.youtube.com/v/#linkfile#&hl=en&fs=1&rel=0&autoplay=1" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="640" height="505"></embed></object></CFOUTPUT>
</body>
</html>
