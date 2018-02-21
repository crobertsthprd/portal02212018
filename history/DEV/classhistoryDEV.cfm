<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>Untitled Document</title>
</head>

<cfquery datasource="#application.reg_dsn#" name="getClassHistory">
select p.firstname, p.lastname, c.description, c.startdt, r.classid, r.regstatus
from dops.reg r, dops.patrons p, dops.classes c
where r.primarypatronid = '28226'
and r.patronid = p.patronid
and r.regstatus = 'E'
and c.classid = r.classid
and c.termid = r.termid
and c.facid =  r.facid
order by p.firstname, c.startdt desc, r.classid desc
</cfquery>

<body>

<CFOUTPUT query="getClassHistory" group="firstname">

<strong>#firstname# #lastname#</strong><br />
<CFOUTPUT>
#description# <i>#dateformat(startdt,'mm/dd/yyyy')#</i><br />
</CFOUTPUT>
<br />

</CFOUTPUT>

</body>
</html>
