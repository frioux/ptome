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
	 * Handles display and processing for a Group field.
	 *
	 * A group field is a set of fields that are combined together using a standard delimiter.
	 * Date fields are a good example of a group field (ex. month day year with a dilimter of '/')
	 * Page ranges are another example (start end with a delimiter of '-')
	 * $options["elements"] - number of individual fields to display
	 * $options["seperator"] - dilimiter for the fields
	 * $options["size"] - size of the form's text input fields
	 * OPTIONAL
	 * $options["maxlength"] - maximum length of text in any given input field
	 * $options["prefix"] - A prefix to prepend to the field data after it has been combined
	 * $options["suffix"] - A suffix to append to the field data after it has been combined
	 *
	 * @author John Oren
	 * @version 1.1 August 4, 2008
	 */
	class Group extends Field {
		/**
		 * Prepares this form field for display.
		 *
		 * @return STRING HTML to display for the form field
		 */
		function display() {
			$options = $this->getOptions();
			$ret = "";
			$value = $this->getValue();
			//since the value came from the database, the prefix and suffix need to be removed and the data split into parts
			$value = substr_replace($value, "", 0, strlen($options["prefix"]));
			$value = substr_replace($value, "", strlen($value)-strlen($options["suffix"]));
			$value = explode($options["seperator"], $value);
			for($i=1; $i <= $options["elements"]; $i++) {
				$ret .= '<input type="text" id="'.$this->getCSSID().$i.'" name="'.$this->getFieldName().Form::DELIMITER.$i.'" value="'.$value[$i-1].'" size="'.$options["size"].'"';
				if(isset($options["maxlength"])) {
					$ret .= ' maxlength="'.$options["maxlength"].'"';
				}
				$ret .= '>';
				if($i != $options["elements"]) {
					$ret .= $options["seperator"];
				}
			}

			$ret .= $this->getErrorText();
			return $ret;
		}

		/**
		 * Processes this field and update the backend used by this field.
		 *
		 * @return BOOLEAN False if errors were encountered
		 */
		function process() {
			$options = $this->getOptions();
			$value = array();
			$this->setEmpty(false);
			for($i=1; $i <= $options["elements"]; $i++) {
				$val = $_POST[$this->getFieldName().Form::DELIMITER.$i];
				if(empty($val)) {
					$this->setEmpty(true);
					break;
				}
				$value[] = $val;
			}

			if($this->isRequired() && $this->isEmpty()) {
				$this->errorText = "Please enter a value";
				return false;
			} elseif($this->isEmpty()) {
				return true;
			}

			if(!is_array($value)) {
				$this->errorText = "Error: The value for this group field was not an array.";
				return false;
			}

			$options = $this->getOptions();
			$ret = $options["prefix"];
			foreach($value as $val) {
				if($this->isRequired() && empty($val)) {
					$this->errorText = "Please enter a value";
					return false;
				} elseif(empty($val)) {
					return true;
				}
				$ret .= $val.$options["seperator"];
			}
			$ret = substr($ret, 0, strlen($ret)-strlen($options["seperator"]));
			$ret .= $options["suffix"];

			return $this->postProcess($ret);
		}

        /**
         * Internal function to evaluate if this field is empty and set the empty flag accordingly.
         *
         * @param MIXED $value Value (or values to check)
         * @return VOID
         */
        protected function setEmpty($value) {
            $this->isEmpty = $value;
        }
	}
?>
