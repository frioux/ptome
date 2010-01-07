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
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");

	/**
	 * Handles an error log for this site.
	 *
	 * Sets up an error log if none exists and handles error logging for this system.
	 *
	 * @author John Oren
	 * @version 1.0 December 30, 2007
	 */
	class ErrorLogManager {
		/**
		 * @static
		 * @final
		 * @var Constant to denote a fatal error.
		 */
		const FATAL = 3;
		/**
		 * @static
		 * @final
		 * @var Constant to denote an error.
		 */
		const ERROR = 7;
		/**
		 * @static
		 * @final
		 * @var Constant to denote a warning.
		 */
		const WARNING = 10;

		/**
		 * Enters the given error message into the database's error log.
		 * Creates the error log if it does not exist.
		 *
		 * @param STRING $msg Error message to store.
		 * @param INTEGER $errorType Type of the error message (corresponding to a constant in this class).
		 * @return VOID
		 */
		static final function log($msg, $errorType) {
			$msg = SecurityManager::SQLPrep($msg);
			$date = date("Y-m-d H:i:s"); //SQL DATETIME format
			DatabaseManager::checkError("INSERT INTO `errorLog` (`time`, `message`, `type`) VALUES ('$date', '$msg', '$errorType')");
            print "This error has been logged. Please contact your system administrator.<br>";
		}
	}
?>
