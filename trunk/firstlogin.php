<?php
    $path = "./";
    $pageTitle = "First Login";
    require_once($path."header.php");
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");

?>
<h1>First Login</h1>

You haven't set your user information yet.  You also need to change your password (it can be the same as before if you want though...)  Let's do that now!<br />

<form name="first_login" action="/cgi-bin/tome/admin.pl" method="post">
   <table>
      <tr>
         <td>
            <font color="red">*</font>
            First Name
         </td>
         <td>
            <input name="first_name" value="TOME" />
      </tr>
      <tr>
         <td>
            <font color="red">*</font>
            Last Name
         </td>
         <td>
            <input name="last_name" value="Program" />
      </tr>
      <tr>
         <td>
            <font color="green">*</font>
            Second Contact
         </td>
         <td>
            <input name="contact" value="panic" />
      </tr>
      <tr>
         <td>
            <font color="red">*</font>
            <font color="blue">*</font>
            LeTourneau Email</td>
            <td><input name="email" value="test@test.com" />
      </tr>
      <tr>
         <td>
            <font color="red">*</font>
            Password
         </td>
         <td>
            <input name="password1" type="password" />
      </tr>
      <tr>
         <td>
            <font color="red">*</font>
            Confirm
         </td>
         <td>
            <input name="password2" type="password" />
      </tr>
      <tr>
         <td colspan="2">
            <input type="submit" value="Save" />
         </td>
      </tr>
  </table>

</form><br />

Notes: 
<br />
<font color="red">*</font> fields are required.<br />
<font color="blue">*</font>This must be a LeTourneau Email address.  Knowing this, you can just put the part before the @-sign if you prefer and it will automatically be added.<br />
<font color="green">*</font>Example: "AIM: perlbeforeswine; Cell: (123) 234-4567"

<?php require_once($path."footer.php"); ?>
