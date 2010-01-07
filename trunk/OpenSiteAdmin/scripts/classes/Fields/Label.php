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

    require_once($path."OpenSiteAdmin/scripts/classes/Fields/Text.php");

	/**
	 * Handles display and processing of a Label field.
	 *
	 * A label is like a hidden field, but it displays the value in the hidden field.
	 * There are no options for this field.
	 *
	 * @author John Oren
	 * @version 1.1 August 4, 2008
	 */
	class Label extends Text {
		/*
		 * Prepares this form field for display.
		 *
		 * @return STRING HTML to display for the form field
		 */
		function display() {
            if(!empty($this->options)) {
                $value = $this->getOptions();
            } else {
                $value = $this->getValue();
            }
			$ret = '<input type="hidden" id="'.$this->getCSSID().'" name="'.$this->getFieldName().'" value="'.$this->getValue().'">'.$value;
			$ret .= $this->getErrorText();
			return $ret;
		}
	}
?>
