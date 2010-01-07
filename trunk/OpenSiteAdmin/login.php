<?php
	/*
	 *	Copyright 2007 John Oren
	 *
	 *	Licensed under the Apache License, Version 2.0 (the "License");
	 *	you may not use this file except in compliance with the License.
	 *	You may obtain a copy of the License at
	 *		http://www.apache.org/licenses/LICENSE-2.0
	 *	Unless required by applicable law or agreed to in writing, software
	 *	distributed under the License is distributed on an "AS IS" BASIS,
	 *	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 *	See the License for the specific language governing permissions and
	 *	limitations under the License.
	 */


	//DEFINE VARIABLES
	$path = "../";
	$error = $_GET["errorID"];

	//INCLUDE REQUIRED FILES AND DECLARE GENERAL OBJECTS
	require_once($path."OpenSiteAdmin/scripts/classes/LoginManager.php");

	//BEGIN CUSTOM CODE
	if(!empty($error) && $error != LoginManager::NONE) {
		print "<font color='red'>";
	}
	switch($error) {
		case LoginManager::UNKNOWN:
			print "An unknown error was encountered while trying to log you in: Please try again.<br>";
			print "If the problem persists, contact your system administrator.";
			break;
		case LoginManager::INVALID:
			print "You have entered an invalid username\password. Please try again.";
			break;
		case LoginManager::SUSPENDED:
			print "Your account has been suspended. Please contact your system administrator.";
			break;
		default:
	}
	if(!empty($error) && $error != LoginManager::NONE) {
		print "</font>";
	}
?>
<html>
    <head>
    	<title>TOME</title>
    </head>
    <body onLoad="document.login.username.focus();">
        <center>
            <img src="<?php print $path; ?>images/tome.png">
                <form action="<?php print $path; ?>OpenSiteAdmin/scripts/login_verify.php?redir=<?php print $_GET['redir']; ?>" method="post" name="login">
                <br>
                <table>
                    <tr>
                        <td>
                            Username
                        </td>
                        <td>
                            <input type="text" name="username" >
                        </td>
                    </tr>
                    <tr>
                        <td>
                            Password
                        </td>
                        <td>
                            <input type="password" name="password">
                        </td>
                    </tr>
                    <tr>
                        <td colspan="2" align="center">
                            <input type="submit" value="Log In">
                        </td>
                    </tr>
                </table>
            </form>
        </center>
    </body>
</html>
