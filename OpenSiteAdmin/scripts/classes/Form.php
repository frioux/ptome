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


	require_once($path."OpenSiteAdmin/scripts/classes/Fieldset.php");

	/**
	 * Manages processing and display for forms on a page.
	 *
	 * @author John Oren
	 * @version 1.2 July 31, 2008
	 */
	class Form {
        /**
		 * @static
		 * @final
		 * @var Mode constant to denote an add type form.
		 */
		const ADD = 1;
		/**
		 * @static
		 * @final
		 * @var Mode constant to denote an edit type form.
		 */
		const EDIT = 2;
		/**
		 * @static
		 * @final
		 * @var Mode constant to denote a delete type form.
		 */
		const DELETE = 3;

		/**
		 * @static
		 * @final
		 * @var Constant for the delimiter between the row prefix ID, fieldname,
		 *		and any field suffixes for a given field's form field name.
		 */
		const DELIMITER = '|';

        /**
		 * @static
		 * @var Next unique form ID.
		 */
		protected static $nextFormID = 1;

        /** @var Unique ID for this form. */
        protected $id;
        /** @var Array of fieldsets in this form. */
		private $fieldsets;
		/** @var The type of this form (one of the type constants). */
		private $formType;
		/** @var URL To redirect to on success (relative or absolute). */
		private $redir;
        /** @var Optional custom text for the submit button. */
        protected $submitText;
        /** @var URL to submit form data to. */
        protected $formAction;

		/**
		 * Constructs a new form manager, which manages all the forms on a page.
		 *
		 * @param INTEGER $type One of the mode constants defined in this class.
		 * @param STRING $redir URL (relative or absolute) to send the user to on successful form processing.
		 * @param STRING $formAction URL (relative or absolute) to submit form data to for processing.
		 */
		function __construct($type, $redir=null, $formAction="") {
            $this->id = Form::$nextFormID++;
			//$type = add\edit\delete - see constants
            $this->formType = $type;
			$this->fieldsets = array();
			if($redir === null) {
				global $path;
				$redir = $path."admin/index.php";
			}
			$this->redir = $redir;
            $this->formAction = $formAction;
		}

		/**
		 * Adds a fieldset to this form.
		 *
		 * @param OBJECT $fieldset The object of type Fieldset to add.
		 * @return VOID
		 */
		function addFieldset(Fieldset $fieldset) {
			$this->fieldsets[] = $fieldset;
		}

        /**
         * Adds a list of fieldsets by adding each fieldset with addFieldset().
         *
         * @param ARRAY $fieldsets List of fieldset objects.
         * @return VOID
         */
		function addFieldsets(array $fieldsets) {
			foreach($fieldsets as $fieldset) {
				$this->addFieldset($fieldset);
			}
        }

        /**
		 * Prepares the form for displays and calls all fieldsets for display
		 *
         * @param BOOLEAN $showUpdate If true, shows an update button
		 * @return VOID
		 */
		function display($showUpdate=false) {
			print '<form method="post" enctype="multipart/form-data" action="'.$this->formAction.'">';
			print '<input type="hidden" name="form'.$this->id.'" value="true">';
            foreach($this->fieldsets as $fieldset) {
				$fieldset->display();
			}
            print '<br>';
            if($showUpdate) {
                print '<input type="submit" name="update" value="Update">&nbsp;&nbsp;&nbsp;&nbsp;';
            }
            print '<input type="submit" name="submit" value="'.$this->getSubmitText($this->formType).'"';
			if($this->formType == Form::DELETE) {
				print ' onClick="return(window.confirm(\'Are you sure you want to permanently delete this?\'))"';
			}
			print '>';
			print '</form>';
        }

        /**
		 * Returns the integer constant representing the type of action this form performs.
		 *
		 * @return INTEGER Form type constant
		 */
		function getFormType() {
			return $this->formType;
        }

        /**
		 * Returns the textual representation for a given mode constant.
		 *
		 * @param INTEGER $mode One of the mode constants defined in this class.
		 * @return STRING Text corresponding to the given mode.
		 */
		static function getModeText($mode) {
			switch($mode) {
				case Form::ADD:
					return "add";
				case Form::EDIT:
					return "edit";
				case Form::DELETE:
					return "delete";
				default:
					print "ERROR: Form type ".$mode." is not supported<br>";
					return "";
			}
		}

		/**
		 * Returns the text for a submit button for a given form type.
		 *
		 * @param INTEGER $mode One of the mode constants defined in this class.
		 * @return STRING Submit button text.
		 */
		function getSubmitText($mode) {
            if(!empty($this->submitText)) {
                return $this->submitText;
            }

			switch($mode) {
				case Form::ADD:
					return "Add Entry";
				case Form::EDIT:
					return "Edit Entry";
				case Form::DELETE:
					return "Delete Entry";
				default:
					return "Unknown Mode "+$mode;
			}
		}

        function getQS() {
            return "form".$this->id."=1";
        }

		/**
		 * Initiates processing for all the fieldset in this form.
		 *
         * If no errors are encountered and there is no hook that equals false,
         * redirects the user to the success page.
		 * Note that all fieldsets will be processed, regardless of previous errors.
         *
         * @param ARRAY $hooks Array of postprocessor hooks to run (returns if one of
         *                      the hooks === false, skipping the redirect)
		 * @return VOID
		 */
		function process(array $hooks=array()) {
			if(!$this->processable()) {
                return false;
            }

            $success = true;
			foreach($this->fieldsets as $fieldset) {
				$success = $fieldset->process() && $success;
			}
            //if successful and this is not an update
			if($success && isset($_POST["submit"])) {
				foreach($this->fieldsets as $fieldset) {
					$success = $fieldset->commit() && $success;
                }
				if($success) {
					foreach($hooks as $hook) {
                        if($hook === false) {
                            return;
                        }
						$hook->process();
					}
                    if(strstr($this->redir, "?") === false) {
    					die(header("Location:".$this->redir."?text=The%20form%20was%20submitted%20succesfully!"));
                    } else {
                        die(header("Location:".$this->redir."&text=The%20form%20was%20submitted%20succesfully!"));
                    }
				}
			}
		}

        /**
         * Returns true if this form is ready to be processed
         *
         * @return BOOLEAN
         */
        function processable() {
            if(!$this->selected() || empty($_GET["id"]) && $mode == Form::ADD) {
                return false;
            }
            return true;
        }

        /**
         * Returns true if this form has been submitted.
         *
         * @return BOOLEAN
         */
        function selected() {
            return array_key_exists("form".$this->id, $_REQUEST);
        }

        /**
         * Sets custom text for the submit button on this form.
         *
         * @param STRING Submit button text
         * @return VOID
         */
        function setSubmitText($text) {
            $this->submitText = $text;
        }
	}
?>
