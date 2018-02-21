<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>Online Registration FAQ</title>
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body>
<table>
	<tr>
		<td>
<!---CFINCLUDE template="/includes/faq.cfm"--->
<CFSCRIPT>
			pageID = 794;
			page = application.contentpickerportal.pageDetails(pageID,"L","false");
			</CFSCRIPT>
			<CFOUTPUT>#page.content#</CFOUTPUT>
			<br><br>
		</td>
	</tr>
</table>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>
</html>
