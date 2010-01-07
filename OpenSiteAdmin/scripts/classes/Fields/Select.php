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
	 * Handles display and processing of a Select field.
	 *
	 * The options parameter is an array of key-value pairs in the following format:
	 * $options[key] = value
	 *
	 * @author John Oren
	 * @version 1.1 August 4, 2008
	 */
	class Select extends Field {
		/**
		 * Prepares this form field for display.
		 *
		 * @return STRING HTML to display for the form field
		 */
		function display() {
			$values = $this->getOptions();
			$ret = '<select id="'.$this->getCSSID().'" name="'.$this->getFieldName().'"';
			if($this->isDelete()) {
				$ret .= ' readonly';
			}
			$ret .= '>';

			$value = $this->getValue();
			foreach($values as $key=>$val) {
				$ret .= '<option value="'.$key.'"';
				if($key == $value) {
					$ret .= ' selected';
				}
				$ret .= '>'.$val.'</option>';
			}
			$ret .= '</select>';
            if($this->ajax) {
                $ret .= $this->ajax->display();
            }

			$ret .= $this->getErrorText();
			return $ret;
		}

		/**
		 * Returns the contents of this field for display in a list.
		 *
         * @param STRING $default Default value to display.
		 * @return STRING Current field value to use in a list.
		 */
		function getListView($default) {
			return $this->options[$default];
		}
	}
?>
