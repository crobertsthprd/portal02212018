<cfquery datasource="#application.reg_dsn#" name="myData">
	select * from dops.getfpdata()
</cfquery>

<!---R0000531549-D-0397EA58-3C8D-43F0-8AB0-74422A5667EF--->

<cfset trans = {StoreId="#myData.STOREID#", TerminalId="#myData.TERMINALID#", TransactionTotal="#form.amountDue#", CaptureMode="true", AddressRequired="true", InvoiceNumber=0, MerchantReferenceCode='#uniqueID#'}>
<CFSET transJSON = serializeJson(trans)>
<CFSET transJSON = replacenocase(transJSON,'":','":"',"all")>
<CFSET transJSON = replacenocase(transJSON,',"','","',"all")>
<CFSET transJSON = replacenocase(transJSON,'}','"}',"all")>
<CFSET transJSON = replacenocase(transJSON,'""','"',"all")>
<CFSET transJSON = replacenocase(transJSON,'STOREID','StoreId',"all")>
<CFSET transJSON = replacenocase(transJSON,'TERMINALID','TerminalId',"all")>
<CFSET transJSON = replacenocase(transJSON,'TRANSACTIONTOTAL','TransactionTotal',"all")>
<CFSET transJSON = replacenocase(transJSON,'CAPTUREMODE','CaptureMode',"all")>
<CFSET transJSON = replacenocase(transJSON,'TRANSACTIONID','TransactionId',"all")>
<CFSET transJSON = replacenocase(transJSON,'INVOICENUMBER','InvoiceNumber',"all")>
<CFSET transJSON = replacenocase(transJSON,'ADDRESSREQUIRED','AddressRequired',"all")>
<CFSET transJSON = replacenocase(transJSON,'MERCHANTREFERENCECODE','MerchantReferenceCode',"all")>

<CFIF mydata.FREEDOMPAYPROXYISUSED>
<cfhttp url="#myData.FREEDOMPAYFREEWAYURL#/createTransaction"
	   method="POST" 
	   proxyserver="#mydata.FREEDOMPAYPROXYIP#" proxyport="#mydata.FREEDOMPAYPROXYPORT#"
	   result="response" 
        timeout="20"  
        charset="utf-8"
> 
        <cfhttpparam type="header" name="Content-Type" value="application/json" /> 
	   <cfhttpparam type="header" name="Cache-Control" value="no-cache" /> 
        <cfhttpparam type="body" value="#trim(transJSON)#">
</cfhttp> 
<CFELSE>
<cfhttp url="#myData.FREEDOMPAYFREEWAYURL#/createTransaction"
	   method="POST" 
	   result="response" 
        timeout="20"  
        charset="utf-8"
> 
        <cfhttpparam type="header" name="Content-Type" value="application/json" /> 
	   <cfhttpparam type="header" name="Cache-Control" value="no-cache" /> 
        <cfhttpparam type="body" value="#trim(transJSON)#">
</cfhttp> 
</CFIF>

<CFSET data = deserializeJSON(response.FILECONTENT)>

<!--- debugging --->
<CFSET debug = true>
<CFIF debug>
	<CFDUMP var="#data#">
</CFIF>
