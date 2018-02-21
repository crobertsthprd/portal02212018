
<CFPARAM name="currentstep" default="5">
<div align="center">
<table style="border-width:1px;border-color:#999;border-style:ridge;background-color:#ddd;margin-bottom:10px;" >
<tr>
<td style="font-size:18px;font-weight:bold;">Checkout</td>
<td width="20" ></td>
<td width="20" align="right"><CFIF currentstep GT 1><img src="/checkout/portal/images/greencheck.png"><CFELSEIF currentstep EQ 1><img src="/checkout/portal/images/whitecheck.png"></CFIF></td>
<td <CFIF currentstep EQ 1>style="background-color:#000;color:#FFF;font-weight:bold;"<CFELSEIF currentstep GT 1><CFELSE></CFIF>>Confirm<br>Selections</td>
<td width="20" align="right"><CFIF currentstep GT 2><img src="/checkout/portal/images/greencheck.png"><CFELSEIF currentstep EQ 2><img src="/checkout/portal/images/whitecheck.png"></CFIF></td>
<td <CFIF currentstep EQ 2>style="background-color:#000;color:#FFF;font-weight:bold;"<CFELSEIF currentstep GT 2><CFELSE></CFIF>>Gift Card<br>Details</td>
<td width="20" align="right"><CFIF currentstep GT 3><img src="/checkout/portal/images/greencheck.png"><CFELSEIF currentstep EQ 3><img src="/checkout/portal/images/whitecheck.png"></CFIF></td>
<td <CFIF currentstep EQ 3>style="background-color:#000;color:#FFF;font-weight:bold;"<CFELSEIF currentstep GT 3><CFELSE></CFIF>>Payment<br>Information</td>
<td width="20" align="right"><CFIF currentstep GT 4><img src="/checkout/portal/images/greencheck.png"><CFELSEIF currentstep EQ 4><img src="/checkout/portal/images/whitecheck.png"></CFIF></td>
<td <CFIF currentstep EQ 4>style="background-color:#000;color:#FFF;font-weight:bold;"<CFELSEIF currentstep GT 4><CFELSE></CFIF>>Confirm Payment &<br />Refund Policy</td>
<td width="20" align="right"><CFIF currentstep GT 5><img src="/checkout/portal/images/greencheck.png"><CFELSEIF currentstep EQ 5><img src="/checkout/portal/images/whitecheck.png"></CFIF></td>
<td <CFIF currentstep EQ 5>style="background-color:#000;color:#FFF;font-weight:bold;"<CFELSEIF currentstep GT 5><CFELSE></CFIF>>Complete<br />Registration</td>
</tr>
</table>
</div>
<br />
