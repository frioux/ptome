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
	 * Handles display and processing of a Password field.
	 *
	 * There are no options for this field.
	 *
	 * @author John Oren
	 * @version 1.1 August 4, 2008
	 */
	class Password extends Field {
		/**
		 * Constructs a password field with a two-line title for the password confirmation box.
		 *
		 * @param STRING $name The name of the database field this form field corresponds to.
		 * @param STRING $title The title to display for this form field.
		 * @param MIXED $options Any options are ignored as this field has no options.
		 * @param BOOLEAN $inList True if this field should be used in a list view.
		 * @param BOOLEAN $required True if this form field is required.
		 */
		function __construct($name, $title, $options, $inList, $required=false) {
			$title .= "<br>";
			if($required) {
				$title .= "*";
			}
			$title .= "Confirm";
			parent::__construct($name, $title, $options, $inList, $required);
		}

		/**
		 * Prepares this form field for display.
		 *
		 * @return STRING HTML to display for the form field
		 */
		function display() {
			$ret = '<input type="password" id="'.$this->getCSSID().'" name="'.$this->getFieldName().'"';
			if($this->isDelete()) {
				$ret .= ' readonly';
			}
			$ret .= '><br><input type="password" id="'.$this->getCSSID().Form::DELIMITER.'2" name="'.$this->getFieldName().Form::DELIMITER.'2"';
			if($this->isDelete()) {
				$ret .= ' readonly';
			}
			$ret .= '>';

			$ret .= $this->getErrorText();
			return $ret;
		}

		/**
		 * Returns the contents of this field for display in a list.
		 *
         * @param STRING $default Default value to display
		 * @return STRING Current field value to use in a list.
		 */
		function getListView($default) {
			return "********";
        }

        protected function postProcess($value) {
            $value[0] = SecurityManager::SQLPrep($value[0]);
            $value[1] = SecurityManager::SQLPrep($value[1]);
            $ret = array($this->getName()=>$value[0], $this->getName()."_salt"=>$value[1]);
            $this->setValue($ret);
            return true;
        }

		/**
		 * Processes this field and update the backend used by this field.
		 *
		 * @return BOOLEAN False if errors were encountered
		 */
		function process() {
			$pass1 = $_POST[$this->getFieldName()];
			$pass2 = $_POST[$this->getFieldName().Form::DELIMITER."2"];

            $currentValue = $this->getValue();
            $this->isEmpty = empty($currentValue) && empty($pass1) && empty($pass2);
			if($this->isEmpty()) {
                if(!$this->isRequired) {
                    return true;
                }
				$this->errorText = "No password was provided - you must provide a password";
				return false;
			} elseif($pass1 != $pass2) {
				$this->errorText = "The passwords did not match";
				return false;
			}

			if(!empty($pass1)) {
                $salt = SecurityManager::generateSalt();
                $password = SecurityManager::encrypt($pass1, $salt);
                return $this->postProcess(array($password, $salt));
			}
			return true;
        }

        /**
		 * Gets the current value of this form field.
         *
		 * @return MIXED Current field value.
		 */
		function getValue() {
            $ret = $this->value;
            if(!empty($ret)) {
                if(is_array($ret)) {
                    foreach($ret as &$item) {
                        $item = SecurityManager::formPrep($item);
                    }
                } else {
                    $ret = SecurityManager::formPrep($ret);
                }
            }
			return $ret;
        }
	}
?>
