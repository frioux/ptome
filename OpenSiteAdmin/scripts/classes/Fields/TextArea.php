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
	 * Handles display and processing of a TextArea field.
	 *
	 * $options["rows"] - Number of rows (lines) in this textarea
	 * $options["cols"] - Number of columns (characters per row) in this textarea
	 *
	 * @author John Oren
	 * @version 1.1 August 4, 2008
	 */
	class TextArea extends Field {
		/**
		 * Prepares this form field for display.
		 *
		 * @return STRING HTML to display for the form field
		 */
		function display() {
			$options = $this->getOptions();

			if(!is_array($options) || count($options) < 2) {
				$msg = 'The textarea '.$this->getName().' does not have a specified width and height.';
				ErrorLogManager::log($msg, ErrorLogManager::FATAL);
				$this->errorText = "A fatal error occured - Contact your System Administrator<br>This error has been logged";
			}
			$value = $this->getValue();
			$ret = '<textarea id="'.$this->getCSSID().'" name="'.$this->getFieldName().'" rows="'.$options["rows"].'" cols="'.$options["cols"].'"';
			if($this->isDelete()) {
				$ret .= ' readonly';
			}
			$ret .= '>'.$value.'</textarea>';

            if($this->ajax) {
                $this->ajax->display();
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

			return $this->postProcess($value);
		}
	}
?>
