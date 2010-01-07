<?php
	/*
	 *	Copyright 2008 John Oren
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


	/**
	 * Handles processing of a truly hidden field tracked through session data.
	 *
	 * There are no options for this field.
	 *
	 * @author John Oren
	 * @version 1.0 August 4, 2008
	 */
	class SessionText extends Hidden {
		/** @var The name of this field (without characters that cause problems in array key names (such as '|')). */
		private $keyName;
        private $value;

		/**
		 * Constructs a form field with information on how to display it.
		 *
		 * @param STRING $name The name of the database field this form field corresponds to.
		 * @param STRING $title The title to display for this form field.
		 * @param MIXED $options Ignored as there are no options for this field.
		 * @param BOOLEAN $inList True if this field should be used in a list view.
		 * @param BOOLEAN $required True if this form field is required.
		 */
		function __construct($name, $title, $options, $inList, $required=false) {
			parent::__construct($name, $title, $options, $inList, $required);
			//create a pseudo-unique (unlikely to already be in use) session key name
			$this->keyName = $name.str_rot13($name);
        }

        /**
		 * Processes this field, updates the current value field, and returns formated data ready for insertion into a SQL database.
		 *
		 * @param STRING $value Value to process
		 * @param INTEGER $mode The type of this form (one of the form type constants defined in the Form class)
		 * @return STRING Formatted string ready for insertion into a SQL database
		 */
		function process($value, $mode) {
			$this->default = $_SESSION[$this->keyName];
            $this->isEmpty = empty($this->default);
			session_unregister($this->keyName);
			unset($_SESSION[$this->keyName]);
			return SecurityManager::SQLPrep($this->default);
		}

		/**
		 * Prepares this form field for display and stores the value being displayed.
		 *
		 * @param STRING $defaultValue Default value to display in this form field
		 * @param BOOLEAN $enabled True if this form field is editable
		 * @return STRING HTML to display for the form field
		 */
		function show($defaultValue, $enabled=true) {
			if(empty($defaultValue) && !empty($this->default)) {
				$defaultValue = $this->default;
			}
			$this->value = $defaultValue;
			$_SESSION[$this->keyName] = $this->value;

			return $this->getErrorText();
		}
	}
?>
