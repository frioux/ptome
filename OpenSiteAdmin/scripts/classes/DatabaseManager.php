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


	require_once($path."OpenSiteAdmin/include.php");
	require_once($path."OpenSiteAdmin/scripts/classes/ErrorLogManager.php");

	/**
	 * Interfaces with the site database.
	 *
	 * Provides an interface to connect to an interact with the database generally.
	 *
	 * @author John Oren
	 * @version 2.0 December 21, 2009
	 */
    class DatabaseManager {
        /** @var The name of the database this database manager is currently connected to. */
		protected $database;
        /** @var Single instance of DatabaseManager. */
        protected static $dbObj;
		/** @var The name of the server this database manager is currently connected to. */
        protected $server;
        /** @var The link resource referring to the currently active database connection. */
		protected $SQL;
		/** @var The username used to establish the current database connection. */
		protected $username;

		/**
		 * Constructs a database manager with a link resource to a MySQL database.
		 *
		 * @param STRING $user The username to use when connecting to the database.
		 * @param STRING $pass The password to use for the given username.
		 * @param STRING $db The name of the database to connect to.
		 * @param STRING $host The name of the server to connect to.
		 */
		protected function __construct($user=DB_USER, $pass=DB_PASS, $db=DB_NAME, $host=DB_ROOT) {
			$this->SQL = mysqli_connect($host, $user, $pass) or die('Could not login: ' . mysqli_connect_error());
			$this->username = $user;
			$this->server = $host;
			if($db != null) {
				mysqli_select_db($this->SQL, $db) or die('Couldn\'t connect to '.$db.'-'.mysqli_error($this->SQL));
				$this->database = $db;
			} else {
				$this->database = null;
			}
        }

        /**
		 * Attempts to change the user used to connect to the database.
		 *
		 * @param STRING $user The username to use when connecting to the database.
		 * @param STRING $pass The password to use for the given username.
		 * @return BOOLEAN True if the new username and password were valid and
		 *				   the connection could be established to the current database.
		 */
		function changeUser($user, $pass) {
			$this->SQL = mysqli_connect($this->server, $this->user, $this->pass);
			if($this->SQL === false) {
				return false;
			}
			$this->username = $user;
			if($this->database != null) {
				$temp = mysqli_select_db($this->SQL, $this->database);
				if($temp === false) {
					return false;
				}
			}
			return true;
        }

        /**
		 * Checks for errors and runs the provided MySQL query.
		 *
		 * @param STRING $query The MySQL query to run.
		 * @return BOOLEAN Query result or false if the row's error flag was set or if the query failed.
		 */
		static function checkError($query) {
			$result = mysqli_query(DatabaseManager::getLink(), $query);
			$error = mysqli_error(DatabaseManager::getLink());
			if(!empty($error)) {
				print "There was an error processing a database request.<br>";
				ErrorLogManager::log("MYSQL ERROR -> $query<br>\n$error", ErrorLogManager::FATAL);
				return false;
			}
            return $result;
		}

        /**
		 * Returns the name of the database this manager is currently connected to.
		 *
		 * @return STRING Currently used database name.
		 */
		function getDatabase() {
			return $this->database;
		}

        /**
         * Wrapper for getting the last insert ID
         *
         * @param RESOURCE The connection resource to reference.
         * @return MIXED false on failure, int on success.
         */
        static function getInsertID($result) {
            return mysqli_insert_id($result);
        }

        /**
         * Wrapper for getting the number of rows returned from a query.
         *
         * @return INT the number of rows in this result set
         */
        static function getNumResults() {
            return mysqli_affected_rows(DatabaseManager::getLink());
        }

        /**
         * Wrapper for getting an array of the next row's data.
         *
         * @param RESOURCE The connection resource to reference.
         * @return INT the number of rows in this result set
         */
        static function fetchArray($result) {
            return mysqli_fetch_row($result);
        }

        /**
         * Wrapper for getting an associative array of the next row's data.
         *
         * @param RESOURCE The connection resource to reference.
         * @return ARRAY The next row's data.
         */
        static function fetchAssoc($result) {
            return mysqli_fetch_assoc($result);
        }

        /**
         * Helper function for fetching all of the rows in the result set into an
         * array of associative arrays.
         *
         * @param MIXED Query resource or a raw query string
         * @return ARRAY Array of associative arrays or an empty array if no results.
         */
        static function fetchAssocArray($result) {
            if(!is_resource($result)) {
                $result = DatabaseManager::checkError($result);
            }
            $ret = array();
            while($row = DatabaseManager::fetchAssoc($result)) {
                $ret[] = $row;
            }
            return $ret;
        }

        /**
         * Constructs an instance of the database manager if necessary and returns a
         * link resource to the database.
		 *
		 * @return RESOURCE Link reource to the database.
		 */
        static function getLink() {
            if(DatabaseManager::$dbObj == null) {
                DatabaseManager::$dbObj = new DatabaseManager();
            }
			return DatabaseManager::$dbObj->getLinkResource();
        }

        /**
         * Returns a link resource to the database.
         *
         * @return RESOURCE Link resource to the database.
         */
        function getLinkResource() {
            return $this->SQL;
        }

        /**
		 * Returns the name of the server this class is currently connected to.
		 *
		 * @return STRING Name of the server this class is currently connected to.
		 */
		function getServer() {
			return $this->server;
		}

        /**
		 * Returns the name of the user currently logged into the database.
		 *
		 * @return STRING Currently active user name.
		 */
		function getUser() {
			return $this->username;
		}

        /**
		 * Checks for errors and runs the provided MySQL queries.
		 * Currently does not support select statements
		 *
		 * @param STRING $query The MySQL queries to run.
		 * @return BOOLEAN false if the row's error flag was set or if the query failed.
		 */
        static function multiCheckError($query) {
            $result = mysqli_multi_query(DatabaseManager::getLink(), $query);
            $error = mysqli_error(DatabaseManager::getLink());
            print $error;
			if(!empty($error)) {
				print "There was an error processing a database request.<br>";
				ErrorLogManager::log("MYSQL ERROR -> $query<br>\n$error", ErrorLogManager::FATAL);
				return false;
			}
            //clean up result set stuff
            while(mysqli_next_result(DatabaseManager::getLink())) mysqli_store_result(DatabaseManager::getLink());
            return true;
        }

		/**
		 * Sets the database this database manager is currently connected to.
		 *
		 * @param STRING $db The name of the database to connect to.
		 * @return VOID
		 */
		function selectDatabase($db) {
			mysqli_select_db(DatabaseManager::getLink(), $db) or die('Couldn\'t connect to '.$db.'-'.mysqli_error(DatabaseManager::getLink()));
			$this->database = $db;
		}
	}
?>
