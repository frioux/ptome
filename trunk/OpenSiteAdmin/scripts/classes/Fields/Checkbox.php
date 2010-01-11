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


	/**
	 * Handles display and processing for a Checkbox field.
	 *
	 * There are no options for this field.
	 *
	 * @author John Oren
	 * @version 1.2 August 4, 2008
	 */
	class Checkbox extends Field {
		/**
		 * Prepares this form field for display.
		 *
		 * @param OBJECT $dbRow A RowManager object to interface with.
		 * @return STRING HTML to display for the form field
		 */
		function display() {
			$ret = '<input type="checkbox" id="'.$this->getCSSID().'" name="'.$this->getFieldName().'"';
			$value = $this->getValue();
			if(!empty($value)) {
				$ret .= ' checked';
			}
			if($this->isDelete()) {
				$ret .= ' readonly';
			}
			$ret .= '>';

			$ret .= $this->getErrorText();
			return $ret;
		}

		/**
		 * Gets the current value of this form field.
         *
         * @param STRING $default Default value to use.
		 * @return STRING Current field value.
		 */
		function getListView($default) {
			if(empty($default) || $default == 0) {
				return "";
			} else {
				//checkmark symbol
				return "&#10003;";
			}
		}

		/**
		 * Processes this field and update the backend used by this field.
		 *
		 * @return BOOLEAN False if errors were encountered
		 */
		function process() {
			$value = strtolower($_POST[$this->getFieldName()]);
            $this->setEmpty($value);
			if($this->isRequired() && $this->isEmpty()) {
				$this->errorText = "Please enter a value";
				return false;
			}

			if(empty($value) || $value == "no") {
                return $this->postProcess("0");
			} elseif($value == "yes" || $value == "on") {
				return $this->postProcess("1");
			} else {
				$errorText = "Unknown value $value";
				return false;
			}
		}
	}
?>
