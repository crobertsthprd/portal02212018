This will test the basic connection to credit card processor. It uses fake card data but makes a true call to processor.<br>
<br>
It should return something similar to <strong>Declined: Invoice xxxxxx: Page 90001: Declined: </strong>
<br>
<br>
ServerIP: <cfoutput>#cgi.server_addr#</cfoutput><br />
<br />

<form name="f" method="POST" action="cctest.cfm">
<input type="Checkbox" name="fullresponse" <cfif IsDefined("fullresponse")>checked</cfif> >
Check to view full XML response
<input type="submit" name="go1" value="Test Processor Connection">
</form>


<cfoutput>

<cfif IsDefined("go1")>

	<cfsavecontent variable="strXML">
		<TranxRequest>
			<GatewayID>54533</GatewayID>
			<Products>1::1::test::THPRD Purchase Invoice</Products>
			<xxxName></xxxName>
			<xxxAddress></xxxAddress>
			<xxxCity></xxxCity>
			<xxxState></xxxState>
			<xxxZipCode></xxxZipCode>
			<xxxCountry>US</xxxCountry>
			<xxxPhone></xxxPhone>
			<xxxCard_Number>4111111111111111</xxxCard_Number>
			<xxxCCMonth>12</xxxCCMonth>
			<xxxCCYear>2020</xxxCCYear>
			<CVV2>123</CVV2>
			<CVV2Indicator>1</CVV2Indicator>
			<xxxTransType>00</xxxTransType>
			<xxxSendCustomerEmailReceipt>N</xxxSendCustomerEmailReceipt>
			<xxxSendMerchantEmailReceipt>N</xxxSendMerchantEmailReceipt>
		</TranxRequest>
	</cfsavecontent>

	<cfset tranx_proctime = GetTickcount()>

	<!--- perform processor call --->
	<cfhttp
		url="https://direct.internetsecure.com/process.cgi"
		method="POST"
		useragent="#CGI.http_user_agent#"
		timeout="300"
		throwonerror="false"
		result="objGet"
		>

		<cfhttpparam type="formfield" name="xxxRequestData" value="#strXML.Trim()#">
		<cfhttpparam type="formfield" name="xxxRequestMode" value="X">
	</cfhttp>
	<!--- end perform processor call --->

	<cfset tranx_proctime = GetTickcount() - tranx_proctime>
	<cfset strXML = objGet.FileContent>

	<cfif IsXml( strXML )>
		<cfset xmlData = XmlParse( strXML )>

		<cfif IsDefined( "xmlData.TranxResponse.Error.XmlText" ) and xmlData.TranxResponse.Error.XmlText neq "">
			<cfset tranx_result = xmlData.TranxResponse.Error.XmlText>

		<cfelseif IsDefined("xmlData.TranxResponse.Page.XmlText") and ListFind( "2000,90000", xmlData.TranxResponse.Page.XmlText )>
			<cfset tranx_result = "Approved: Invoice xxxxxx: Page " & xmlData.TranxResponse.Page.XmlText & ": " & xmlData.TranxResponse.Verbiage.XmlText & ": Receipt " & xmlData.TranxResponse.ReceiptNumber.XmlText & " (" & tranx_proctime & " ms)">

		<cfelseif IsDefined( "xmlData.TranxResponse.Page.XmlText" ) and xmlData.TranxResponse.Page.XmlText neq "">
			<cfset tranx_result = "Declined: Invoice xxxxxx: Page " & xmlData.TranxResponse.Page.XmlText & ": " & xmlData.TranxResponse.Verbiage.XmlText & ": Receipt " & xmlData.TranxResponse.ReceiptNumber.XmlText & " (" & tranx_proctime & " ms)">

		</cfif>

	<cfelse>
		<cfset tranx_result = "Invalid request (Bad XML returned)" & " " & strXML>

	</cfif>

	<strong>Results:</strong><br>

	#tranx_result#<br><br>

	<!--- toggle on to see full response --->
	<cfif IsDefined("fullresponse")>
		<cfdump var="#xmlData#">
	</cfif>

</cfif>

</cfoutput>
</body>
</html>
