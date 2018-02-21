<cfquery datasource="#application.reg_dsn#" name="myData">
	select * from dops.getfpdata()
</cfquery>

<CFIF NOT Isdefined("application.serverAddress")>
	<CFSET useproxy = false>
<CFELSE>
	<CFIF application.serverAddress EQ application.internalIP>
     	<CFSET useproxy = true>
     <CFELSE>
     	<CFSET useproxy = false>
     </CFIF>
</CFIF>

<CFIF useproxy>
<cfhttp url="#myData.FREEDOMPAYFREEWAYURL#/GetTransaction"
	   method="POST" 
	   proxyserver="#mydata.FREEDOMPAYPROXYIP#" proxyport="#mydata.FREEDOMPAYPROXYPORT#"
	   result="response" 
        timeout="20"  
        charset="utf-8"
> 
        <cfhttpparam type="header" name="Content-Type" value="application/json" /> 
	   <cfhttpparam type="header" name="Cache-Control" value="no-cache" /> 
        <cfhttpparam type="body" value="""#form.transid#""">
</cfhttp> 
<CFELSE>
<cfhttp url="#myData.FREEDOMPAYFREEWAYURL#/GetTransaction"
	   method="POST" 
	   result="response" 
        timeout="20"  
        charset="utf-8"
> 
        <cfhttpparam type="header" name="Content-Type" value="application/json" /> 
	   <cfhttpparam type="header" name="Cache-Control" value="no-cache" /> 
        <cfhttpparam type="body" value="""#form.transid#""">
</cfhttp> 
</CFIF>

<CFSET data = deserializeJSON(response.FILECONTENT)>

<!--- debugging --->
<CFSET debug = false>
<CFIF debug>
	<CFDUMP var="#data#">
</CFIF>
