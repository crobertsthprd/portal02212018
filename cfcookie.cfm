<CFSET _cookie = GetHttpRequestData().headers.cookie>

<br />

<hr />

CFCOOKIE:<br />
<CFDUMP var="#cookie#">

_cookie:<br />
<CFDUMP var="#_cookie#">


<hr>

val('NULL') = <CFOUTPUT>#val('NULL')#</CFOUTPUT><br>
val(' ') = <CFOUTPUT>#val(' ')#</CFOUTPUT><br>
val('') = <CFOUTPUT>#val('')#</CFOUTPUT><br>

