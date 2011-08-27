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
	$page = "site";
	$path = "../";

	//INCLUDE REQUIRED FILES AND DECLARE GENERAL OBJECTS
	require_once($path."OpenSiteAdmin/scripts/classes/LoginManager.php");

	if(isset($_REQUEST["username"])) {
		$mgr = new LoginManager($_REQUEST["redir"]);
		$error = $mgr->login($_REQUEST["username"], $_REQUEST["password"], $_REQUEST["remember"], isset($_COOKIE["username"]));
		//BEGIN CUSTOM CODE
		if($error != LoginManager::NONE) {
			print '<span style="color:red">';
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
			print "</span>";
		} else {
			$securityCheck = new SecurityManager();
			if(!$securityCheck->isPageVisible($page)) {
				print '<span style="color:red;">'.$securityCheck->getErrorMessage($page).'</span>';
			} else {
				$id = $mgr->getUserID();
				$query = "SELECT users.firstLogin
							FROM users
							WHERE users.ID = '".$id."';";

				$resultSet = DatabaseManager::checkError($query);
				$row = DatabaseManager::fetchArray($resultSet);
				//check for a custom redirect
				if($row[0] == 0) {
				   $mgr->setRedirect($path."firstlogin.php");
				}

				$mgr->redirect();
			}
		}
	}

	$redir = isset($_GET["redir"])?$_GET['redir']:$path."index.php";
?>
<html>
    <head>
    	<title>TOME</title>
    </head>
    <body onLoad="document.login.username.focus();">
        <center>
            <img src="<?php print $path; ?>images/tome.png">
                <form method="post" action="">
				<input type="hidden" name="redir" value="<?php print $redir; ?>">
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
                        <td style="text-align:right">
                            <input type="checkbox" name="remember">
                        </td>
                        <td>
                            Stay signed in
                        </td>
                    </tr>
                    <tr>
                        <td colspan="2" align="center">
                            <input type="submit" value="Log In">
                        </td>
                    </tr>
                </table>
				<br>
				<a href="<?php print $path; ?>admin/pages/contact.php?login=1">Need help?</a>
            </form>
        </center>
    </body>
</html>
