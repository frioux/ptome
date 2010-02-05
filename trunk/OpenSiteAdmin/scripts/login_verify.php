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


	session_start();
	$path = "../../";
	//set up the variable for the current number of login attempts
	if(!isset($_SESSION["loginAttempts"])) {
		$_SESSION["loginAttempts"] = 0;
	}
	$_SESSION["loginAttempts"]++;

    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");
	require_once($path."OpenSiteAdmin/scripts/classes/LoginManager.php");

	$loginManager = new LoginManager();

	//process the login
	$errorID = LoginManager::UNKNOWN;
	//if the user has exceeded the number of allowed logins...
	if($_SESSION["loginAttempts"] > LoginManager::MAX_LOGIN_ATTEMPTS) {
		//...suspend the user account
		$loginManager->suspend($_POST["username"]);
		//...notify the user of their suspension
		$errorID = LoginManager::SUSPENDED;
		//...allow the user to log in if an administrator reactivates their account
		$_SESSION["loginAttempts"] = 0;
		header("Location:".$path."OpenSiteAdmin/login.php?errorID=".$errorID);
	}

	//process login data
	if(isset($_POST["username"])) {
		$errorID = $loginManager->login($_POST["username"], $_POST["password"], $_POST["remember"]);
	} else {
		$errorID = $loginManager->login($_COOKIE["username"], $_COOKIE["password"], "no", true);
	}

    $id = $loginManager->getUserID();
    $hasLoggedIn = 1;
    if(!empty($id)) {
        $query = "SELECT users.firstLogin
                    FROM users
                    WHERE users.ID = '".$id."';";

        $resultSet = DatabaseManager::checkError($query);
        $row = DatabaseManager::fetchArray($resultSet);
        $hasLoggedIn = $row[0];
    }

    //check for a custom redirect
    if($hasLoggedIn == 0) {
       $redir = $path."firstlogin.php";
    } elseif(isset($_GET["redir"]) && !empty($_GET["redir"])) {
        $redir = $_GET["redir"];
    } else {
        $redir = $path."index.php";
    }
    //redirect based on error status
	if($errorID === LoginManager::NONE) {
        $_SESSION["loginAttempts"] = 0;
		header("Location:".$redir);
	} else {
		header("Location:".$path."OpenSiteAdmin/login.php?redir=".$redir."&errorID=".$errorID);
	}
?>
