<cfquery datasource="#application.reg_dsn#" name="myData">
	select * from dops.getfpdata()
</cfquery>



<!---
<CFSET terminalID = "2454820014">
<CFSET storeID = "1452148014">
<CFSET terminalID = "2454814012">
<CFSET storeID = "1452138016">
--->

<cfset trans = {StoreId="#myData.STOREID#", TerminalId="#myData.TERMINALID#", AddressRequired="true"}>
<CFSET transJSON = serializeJson(trans)>
<CFSET transJSON = replacenocase(transJSON,'":','":"',"all")>
<CFSET transJSON = replacenocase(transJSON,',"','","',"all")>
<CFSET transJSON = replacenocase(transJSON,'}','"}',"all")>

<CFSET transJSON = replacenocase(transJSON,'""','"',"all")>

<CFSET transJSON = replacenocase(transJSON,'STOREID','StoreId',"all")>
<CFSET transJSON = replacenocase(transJSON,'TERMINALID','TerminalId',"all")>
<CFSET transJSON = replacenocase(transJSON,'ADDRESSREQUIRED','AddressRequired',"all")>


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
<cfhttp url="#myData.FREEDOMPAYFREEWAYURL#/createTokenTransaction"
	   method="POST" 
	   proxyserver="#mydata.FREEDOMPAYPROXYIP#" proxyport="#mydata.FREEDOMPAYPROXYPORT#"
	   result="response" 
        timeout="20"  
        charset="utf-8"
> 
        <cfhttpparam type="header" name="Content-Type" value="application/json" /> 
	   <cfhttpparam type="header" name="Accept" value="application/json" /> 
	   <cfhttpparam type="header" name="Cache-Control" value="no-cache" /> 
        <cfhttpparam type="header" name="Content-Length" value="#len(transJSON)#" /> 
        <cfhttpparam type="body" value="#trim(transJSON)#">
</cfhttp> 
<CFELSE>
<cfhttp url="#myData.FREEDOMPAYFREEWAYURL#/createTokenTransaction"
	   method="POST" 
	   result="response" 
        timeout="20"  
        charset="utf-8"
> 
        <cfhttpparam type="header" name="Content-Type" value="application/json" /> 
	   <cfhttpparam type="header" name="Accept" value="application/json" /> 
	   <cfhttpparam type="header" name="Cache-Control" value="no-cache" /> 
        <cfhttpparam type="header" name="Content-Length" value="#len(transJSON)#" /> 
        <cfhttpparam type="body" value="#trim(transJSON)#">
</cfhttp> 
</CFIF>

<CFSET data = deserializeJSON(response.FILECONTENT)>

<!--- debugging --->
<CFSET debug = false>
<CFIF debug>
	<CFDUMP var="#data#">
</CFIF>

