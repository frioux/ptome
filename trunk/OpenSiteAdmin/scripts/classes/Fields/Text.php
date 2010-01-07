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
	 * Handles display and processing of a Text field.
	 *
	 * OPTIONAL
	 * $options["size"] - size of the form's text input field
	 * $options["maxlength"] - maximum length of text input field
	 *
	 * @author John Oren
	 * @version 1.1 August 4, 2008
	 */
	class Text extends Field {
		/**
		 * Prepares this form field for display.
		 *
		 * @return STRING HTML to display for the form field
		 */
		function display() {
			$options = $this->getOptions();

			$ret = '<input type="text" id="'.$this->getCSSID().'" name="'.$this->getFieldName().'" value="'.$this->getValue().'"';
			if(!empty($options["size"])) {
				$ret .= ' size="'.$options["size"].'"';
			}
			if(!empty($options["maxlength"])) {
				$ret .= ' maxlength="'.$options["maxlength"].'"';
			}
			if($this->isDelete()) {
				$ret .= ' readonly';
			}
			$ret .= '>';

            if($this->ajax) {
                $ret .= $this->ajax->display();
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
			$value = $_POST[$this->getFieldName()];
            $this->setEmpty($value);
			if($this->isRequired() && $this->isEmpty()) {
				$this->errorText = "Please enter a value";
				return false;
			}
			$options = $this->getOptions();
			if(!empty($options["maxlength"])) {
				if(strlen($value) > $options["maxlength"]) {
					//HTML should enforce this, but the user can disable it with browser extensions.
					$this->errorText = "The provided value was longer than the maximum allowed length";
					return false;
				}
			}

			return $this->postProcess($value);
		}
	}
?>
