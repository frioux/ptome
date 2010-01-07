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

    require_once($path."OpenSiteAdmin/scripts/classes/Fields/Select.php");

	/**
	 * Handles display and processing of a Radio Button field.
	 *
	 * The options parameter is an array of key-value pairs in the following format:
	 * $options[key] = value
	 *
	 * @author John Oren
	 * @version 1.1 August 4, 2008
	 */
	class RadioButtons extends Select {
		/**
		 * Prepares this form field for display.
		 *
		 * @return STRING HTML to display for the form field
		 */
		function display() {
			$values = $this->getOptions();
            $value = $this->getValue();
            $ret = "";
            $i = 0;
            foreach($values as $key=>$val) {
                $ret .= $val.':<input type="radio" id="'.$this->getCSSID().$i++.'" name="'.$this->getFieldName().'" value="'.$key.'"';
                if($this->isDelete()) {
                    $ret .= ' readonly';
                }
                if($key == $value) {
					$ret .= ' checked';
				}
                $ret .= '>&nbsp;';
            }
			$ret .= $this->getErrorText();
			return $ret;
		}
	}
?>