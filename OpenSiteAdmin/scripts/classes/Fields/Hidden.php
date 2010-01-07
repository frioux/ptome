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
	 * Handles display and processing of a Hidden field.
	 *
	 * There are no options for this field.
	 *
	 * @author John Oren
	 * @version 1.1 August 4, 2008
	 */
	class Hidden extends Field {
		/**
		 * Prepares this form field for display.
		 *
		 * @return STRING HTML to display for the form field
		 */
		function display() {
			$ret = '<input type="hidden" id="'.$this->getCSSID().'" name="'.$this->getFieldName().'" value="'.$this->getValue().'">';

			$ret .= $this->getErrorText();
			return $ret;
		}

        /**
		 * Returns the display name (title) of this form field.
		 * Hidden fields should never reveal an asterisk, even if they are required
         *
         * @param BOOLEAN $isList Excludes the visual queue for required fields in list view
		 * @return STRING The name to display with this form field.
		 */
		function getTitle($isList=false) {
            return $this->title;
        }

        /**
		 * Processes this field and update the backend used by this field.
		 *
		 * @return BOOLEAN False if errors were encountered
		 */
        function process() {
            $value = $_POST[$this->getFieldName()];
			$this->setEmpty($value);
			return $this->postProcess($value);
        }
	}
?>