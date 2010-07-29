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

    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");

	/**
	 * Provides permission checking and encryption methods for the site.
	 *
	 * @author John Oren
	 * @version 1.3 July 31, 2008
	 */
    class SecurityManager {
        /** @var Array of error messages created by the setPermissions() method. */
		private $errorMessages;
		/** @var Array of permissions levels created by the setPermissions() method. */
		private $permissions;

		/**
		 * Sets up the security manager with access to a database and an optional page to check permissions on.
		 *
		 * @param STRING $page The name of a page to check.
		 * @param STRING $mode An optional suffix to add to the page name, such as Add, Edit, or Delete.
		 */
		function __construct($page="", $mode="") {
			$this->setPermissions();
			if(!empty($page)) {
				$this->validatePage($mode.$page);
			}
        }

        /**
		 * Encrypts the given string using the specified hashing algorithm.
		 * See the end of /OpenSiteAdmin/scripts/php.php for a list of available hashing algorithms.
         * If the first option provided in this method is not available, try the algorithms in order from
         * top to bottom for maximum security. The md5 function is provided as a last resort and is not
         * recommended for applications needing to withstand organized security threats in future years.
		 *
		 * @param STRING $string The string to encrypt.
		 * @param STRING $salt Salt to use on the given string
		 * @return STRING Encrypted text (usually significantly longer than the input text).
		 */
		static function encrypt($string, $salt) {
			return hash("sha512", $salt.$string);
			//return hash("sha384", $salt.$string);
			//return hash("whirlpool", $salt.$string);
			//return md5($salt.$string);
        }

        /**
		 * Removes formatting added by SQLPrep.
		 *
		 * @param STRING String to be formatted
		 * @return STRING Formatted string with formatting from SQLPrep removed
		 */
		static final function formPrep($string) {
			return htmlspecialchars_decode(stripslashes($string));
		}

        /**
		 * Generates a pseudo-random string for use with password hashing.
		 *
		 * @return STRING A pseudo-random 32 character string.
		 */
		static function generateSalt() {
			return md5(mt_rand()*M_LOG2E);
		}

		/**
		 * Returns an array keyed by a user level's access level with values for the name of the particular access level.
		 *
		 * @return ARRAY $ret[levelNum] = levelName
		 */
		static function getAccessLevels() {
			return array(1=>"Developer", 2=>"Administrator", 3=>"User");
        }

        /**
		 * Acts like PHP's basename($url, ".php") function, but also strips off any _GET variables in the URL.
		 *
		 * @param STRING $url URL to process.
		 * @return STRING page name (no path information, no file extension, no _GET variable or anchor (#) information).
		 */
		function getBaseName($url) {
			$ret = basename($url);
			$ret = explode(".php", $ret);
			return $ret[0];
        }

        /**
		 * Verifies that the current user is allowed to view the specified page.
		 *
		 * @param STRING $page The page to check permissions for.
		 * @return BOOLEAN False if the user is not allowed to view the page or
		 *				   exits with an error message if the page has no permissions.
		 */
		function isPageVisible($page) {
			if(!isset($_SESSION["username"])) {
				return false;
			}

			if(!isset($this->permissions[$page])) {
				$page = $this->getBaseName($_SERVER["REQUEST_URI"]);
				if(!isset($this->permissions[$page])) {
					die("This page has no authorization level. No one can view it. Please contact a developer to add $page into the authorization system");
				}
			}
			if(isset($_SESSION["permissions"]) && $_SESSION["permissions"] <= $this->permissions[$page]) {
				return true;
			} else {
				return false;
			}
		}

        /**
		 * Verifies that the current user is allowed to view at least one of an add, edit, or delete page.
		 *
		 * @param STRING $pageSuffix Suffix for add, edit, and delete (ex. add$pageSuffix).
		 * @return BOOLEAN False if the current user is not allowed to view the specified 'row' of pages.
		 */
		function isRowVisible($pageSuffix) {
			if(!isset($_SESSION["permissions"]))
				return false;

			$lvl = $_SESSION["permissions"];

			$page = "add".$pageSuffix;
			if($lvl <= $this->permissions[$page])
				return true;
			$page = "edit".$pageSuffix;
			if($lvl <= $this->permissions[$page])
				return true;
			$page = "delete".$pageSuffix;
			if($lvl <= $this->permissions[$page])
				return true;

			return false;
		}

		/**
		 * Sets arrays of permission levels and error messages corresponding to the keys from getAccessLevels()
		 * for every page registered with the system.
		 *
         * @return VOID
		 */
		function setPermissions() {
			$permissions = array();

			$result = DatabaseManager::checkError("select * from access");
			while($row = DatabaseManager::fetchAssoc($result)) {
				$this->permissions[$row["pageName"]] = $row["minLevel"];
				$this->errorMessages[$row["pageName"]] = $row["message"];
			}
        }

        /**
		 * Formats a string for entry into a SQL database.
		 *
		 * @param STRING String to be formatted
		 * @return MIXED If succesful, a formatted string ready for insertion into a SQL database
		 *               If errors, an array of error messages
		 */
		static final function SQLPrep($string) {
			return htmlspecialchars(mysqli_real_escape_string(DatabaseManager::getLink(), $string));
		}

		/**
		 * Checks if a page is visible. If it is not visible, redirects the user to the site's login page.
		 *
		 * @param STRING $page The page to check permissions for.
		 * @return VOID Redirects the user if they cannot access the specified page.
		 */
        function validatePage($page) {
			if(!isset($_SESSION["username"])) {
                global $path;
                if(isset($_GET["redir"]) && !empty($_GET["redir"])) {
                    $redir = $_GET["redir"];
                } else {
                    $redir = $_SERVER["REQUEST_URI"];
                }
				die(header("Location:".$path."admin/login.php?redir=".$redir));
            }
			if(!$this->isPageVisible("admin") && $page != "index") {
                global $path;
				die(header("Location:".$path."admin/index.php?text=".$this->errorMessages["admin"]));
            }
            if(!$this->isPageVisible($page)) {
				global $path;
				die(header("Location:".$path."admin/index.php?text=".$this->errorMessages[$page]));
            }
		}
	}
?>
