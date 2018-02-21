<CFIF findnocase('patronhistory.cfm',cgi.HTTP_REFERER) EQ 0> 
	<CFLOCATION url="http://www.thprd.org">
</CFIF>

<CFQUERY name="getDoc" datasource="#application.common_dsn#">
	select d.*,r.*,u.docfolder
	from documents d, documentsref r, documentsusagelist u
	where d.docid = r.docid
	and r.docusage = u.usagecode
	and d.docid = #url.docid#
	
	order by d.docfilename
</CFQUERY>



<CFIF fileexists("/srv/www/htdocs/www/docs/#getDoc.publicwebfilename#")>

<CFHTTP method="get" url="http://www.thprd.org/docs/#getDoc.publicwebfilename#" getasbinary="auto">
<CFIF cfhttp.mimetype NEQ "text/html">
	<CFCONTENT variable="#CFHTTP.FileContent#" type="#CFHTTP.MIMEType#">
<CFELSE>
	<CFOUTPUT>#CFHTTP.FileContent#</CFOUTPUT>
</CFIF>

<CFELSE>
	The requested file is currently unavailable. Please try again later.
</CFIF>