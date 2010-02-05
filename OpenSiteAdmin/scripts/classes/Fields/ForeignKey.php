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
	 * Handles display and processing for a ForeignKey field.
	 *
	 * A foreign key gets its value from a key field which must be processed before
	 * this field.
	 * $option = Instance of class Field
	 *
	 * @author John Oren
	 * @version 1.1 August 4, 2008
	 */
	class ForeignKey extends Field {
        /**
		 * Constructs a form field with information on how to display it.
		 *
		 * @param STRING $name The name of the database field this form field corresponds to.
		 * @param STRING $title The title to display for this form field.
		 * @param MIXED $options The options associated with this form field.
		 * @param BOOLEAN $inList True if this field should be used in a list view.
		 * @param BOOLEAN $required True if this form field is required.
		 */
		function __construct($name, $title, $options, $inList, $required=false) {
            if($options instanceof self) {
                throw new Exception("ERROR: You are not allowed to chain foreign keys. It just gets messy...");
            }
            if(!$options instanceof Field) {
                throw new Exception("ERROR: Foreign Keys must have an object of type Key as a parameter");
            }
            parent::__construct($name, $title, $options, $inList, $required);
            $this->setKey();
		}

        /**
         * Hack to allow foreign keys to process correctly if they are called
         * before their associated key gets processed.
         *
         * @return BOOLEAN False if unsuccessful
         */
        function databasePrep() {
			return $this->process();
		}

		/**
		 * Prepares this form field for display.
		 *
		 * @return STRING HTML to display for the form field
		 */
		function display() {
			$option = $this->getOptions();
			if(!($option instanceof Field)) {
				if(empty($this->errorText)) {
					$this->errorText = "FATAL ERROR: Foreign Keys must have an object of type Key as a parameter";
				}
			} else {
				$ret = '<input type="hidden" id="'.$this->getCSSID().'" name="'.$this->getFieldName().'" value="'.$option->getValue().'">';
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
            $value = $this->getOptions()->getValue();
            $this->setEmpty($value);
            $this->setValue($value);
			return true;
        }
	}
?>
