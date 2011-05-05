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

	require_once($path."OpenSiteAdmin/scripts/classes/SecurityManager.php");

	/**
	 * Handles processing and security for the site's login process.
	 *
	 * @author John Oren
	 * @version 1.2 July 31, 2008
	 */
	class LoginManager {
		/**
		 * @static
		 * @final
		 * @var The maximum number of login attempts that can be made before a user's account is suspended.
		 */
		const MAX_LOGIN_ATTEMPTS = 15;

        /**
		 * @static
		 * @final
		 * @var Error code constant - the provided username and\or password was invalid.
		 */
		const INVALID = 1;
		/**
		 * @static
		 * @final
		 * @var Error code constant - no errors where encountered.
		 */
        const NONE = 2;
        /**
		 * @static
		 * @final
		 * @var Error code constant - The specified account has been suspended.
		 */
		const SUSPENDED = 3;
		/**
		 * @static
		 * @final
		 * @var Error code constant - an unknown error was encountered.
		 */
		const UNKNOWN = 4;

		/** Primary key for the current user logging/logged in. */
        protected $userID;
		/** The URL to redirect the user to. */
		protected $redir;

		/**
		 * Constructs a new login manager that will redirect to the given URL.
		 *
		 * @param $redir The URL to redirect to.
		 */
		public function __construct($redir) {
			$this->setRedirect($redir);

			//set up the variable for the current number of login attempts
			if(!isset($_SESSION["loginAttempts"])) {
				$_SESSION["loginAttempts"] = 0;
			}
			$_SESSION["loginAttempts"]++;

			if($_SESSION["loginAttempts"] > LoginManager::MAX_LOGIN_ATTEMPTS) {
				//...suspend the user account
				LoginManager::suspend($_POST["username"]);
				//...allow the user to log in if an administrator reactivates their account
				$_SESSION["loginAttempts"] = 0;
				//...notify the user of their suspension
				global $path;
				header("Location:".$path."admin/login.php?errorID=".LoginManager::SUSPENDED);
			}
		}

		/**
		 * Returns false if there is no error, otherwise returns an error code.
		 *
		 * @return INT Error constant from this class.
		 */
		public static function isError() {
			$error = $_REQUEST["errorID"];
			if(!empty($error) && $error != LoginManager::NONE) {
				return $error;
			}
			return false;
		}

		/**
		 * Attempts to log a user into the site's administrative system.
		 *
		 * @param STRING $user Username to use to login.
		 * @param STRING $pass Password to attempt to use with the given user.
		 * @param STRING $remember If set to "yes", the user's login information will be saved in cookies if it validates sucessfully.
		 * @param BOOLEAN $isCookie True if the provided data is coming from cookie data (cookie passwords are already encrypted).
		 * @return INTEGER One of the error code constants defined in this class.
		 */
		public function login($user, $pass, $remember=false, $isCookie=false) {
            $user = SecurityManager::SQLPrep($user);
            $pass = SecurityManager::SQLPrep($pass);
			$sql = "select `users`.*, `libraries`.`interTOME` from `users` JOIN `libraries` ON `users`.`libraryID` = `libraries`.`ID` where `username` LIKE '$user'";
			$result = DatabaseManager::checkError($sql);
			if(DatabaseManager::getNumResults($result) === 0) {
				return LoginManager::INVALID;
			}
			$row = DatabaseManager::fetchAssoc($result);
			if($row["active"] == "1") {
				if($isCookie) {
					$pass2 = SecurityManager::encrypt($row["password"], $row["password_salt"]);
				} else {
					$pass2 = $row["password"];
				}
				if(SecurityManager::encrypt($pass, $row["password_salt"]) == $pass2 || crypt($pass, $pass2) == $pass2) {
                    if(crypt($pass, $pass2) == $pass2) {
                        //temporary conversion script
                        $salt = SecurityManager::generateSalt();
                        $password = SecurityManager::encrypt($pass, $salt);
                        DatabaseManager::checkError("update `users` set `password` = '".$password."', `password_salt` = '".$salt."' where `ID` = ".$row["ID"]);
                    }
					$_SESSION["ID"] = $row["ID"];
                    $this->userID = $row["ID"];
                    $_SESSION["libraryID"] = $row["libraryID"];
                    $_SESSION["interTOME"] = $row["interTOME"];
					$_SESSION["username"] = $row["username"];
					$_SESSION["permissions"] = $row["permissions"];
                    $_SESSION["semester"] = $row["semester"];
					$_SESSION["notifications"] = $row["notifications"];
					$_SESSION["email"] = $row["email"];
					if($remember == "on") {
						$this->setCookies($row["username"], $pass2, true);
					}
					return LoginManager::NONE;
				} else {
					return LoginManager::INVALID;
				}
			} else {
				return LoginManager::SUSPENDED;
			}
			return LoginManager::UNKNOWN;
		}

		/**
		 * Logs the user out and obliterates their session.
		 *
		 * @return VOID
		 */
		public static function logout() {
			if(!isset($_SESSION) || empty($_SESSION)) {
				session_start();
			}
			if(empty($_SESSION["ID"])) {
				//don't let people get around the suspension system by logging out between login attempts.
				return;
			}
			//destroy session data
			$_SESSION = array();
			//delete cookies
			if(isset($_COOKIE["username"])) {
				LoginManager::setCookies("", "", false);
			}
			//formally destroy the session
			session_destroy();
		}

        /**
         * Returns the primary key for the current user
         *
         * @return INT
         */
        public function getUserID() {
            return $this->userID;
        }

		/**
		 * Assumes the user is logged in and redirects them properly.
		 *
		 * @return VOID
		 */
		public function redirect() {
			$_SESSION["loginAttempts"] = 0;
			die(header("Location:".$this->redir));
		}

		/**
		 * Sets (or unsets) cookies with secure user information to automatically log them in.
		 *
		 * @param STRING $username Username.
		 * @param STRING $password Encrypted password.
		 * @param BOOLEAN $set If false, unsets the cookies instead of setting them.
		 * @return VOID
		 */
		protected static function setCookies($username, $password, $set) {
			//60*60*24*365 = 1 year
			$offset = 60*60*24*365;
			if(!$set) {
				$offset = -$offset;
			}
			$time = time()+$offset;
			setcookie( "username", $username, $time, "/");
			setcookie( "password", $password, $time, "/");
		}

		/**
		 * Sets the redirect URL to a new location.
		 *
		 * @param STRING $redir The new URL to redirect to.
		 * @return VOID
		 */
		public function setRedirect($redir) {
			$this->redir = $redir;
		}

		/**
		 * Attempts to suspend the account associated with the given username.
		 *
		 * @param STRING $user Username for the account to suspend.
		 * @return VOID
		 */
		public static function suspend($user) {
			$sql = "select * from `users` where `username` = '$user'";
			$result = DatabaseManager::checkError($sql);
			if(DatabaseManager::getNumResults($result) === 0) {
				return;
			}
			$row = DatabaseManager::fetchAssoc($result);
			$sql = "update `users` set `active` = '0' where `ID` = '".$row['ID']."'";
			DatabaseManager::checkError($sql);
		}
	}
?>
