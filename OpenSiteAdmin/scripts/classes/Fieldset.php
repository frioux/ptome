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


	//include all of the standard forms
	require_once($path."/OpenSiteAdmin/scripts/classes/Fieldsets/Fieldset_Horizontal.php");
	require_once($path."/OpenSiteAdmin/scripts/classes/Fieldsets/Fieldset_Vertical.php");

	/**
	 * Provides a template for creating HTML forms.
	 *
     * Handles display and processing of a group of form fields interfacing with a single
     * row in a database.
	 *
	 * @author John Oren
	 * @version 1.4 August 4, 2008
	 */
    abstract class Fieldset {
        /** @var Array of database rows associated with this form. */
		protected $dbRows;
        /** @var An array of all the fields associated with this form. */
		protected $fields;
		/** @var The integer type of the form this fieldset is in. */
        protected $formType;
        /** @var True if none of the fields in this fieldset have data. */
        protected $isEmpty;
		/** @var False if form field labels should be suppressed. */
		protected $showLabels;
        /**
         * @var If a fieldset is silent and empty, no errors are displayed and the
         *       fieldset processes and commits successfully (though nothing
         *       actually happens). However, if a field is silent and not empty,
         *       silent mode is disabled, and errors and processing occur normally.
         */
        protected $silent;
        /** @var Array of key-pair values in the form $values[fieldName] = value. */
		protected $values;

		/**
		 * Constructs a new fieldset in the given form with no fields.
         *
         * @param INTEGER $formType The form this fieldset is part of.
         * @param BOOLEAN $showLables If true, field titles are shown.
         * @param BOOLEAN $silent See comments on class member $silent.
		 */
		function __construct($formType, $showLabels=true, $silent=false) {
			$this->formType = $formType;
			$this->showLabels = $showLabels;
            $this->isEmpty = true;
            $this->silent = $silent;
            $this->dbRows = array();
            $this->fields = array();
            $this->values = array();
		}

		/**
		 * Adds a field to this fieldset.
		 *
		 * @param OBJECT $field The object of type Field to add.
		 * @param MIXED $default Optional default value for this field
		 * @return STRING The form name for this field.
		 */
		function addField(Field $field, $default=null) {
            $field->setFormType($this->formType);
            $field->setSilent($this->silent);
            if(!empty($this->values[$field->getFieldName()])) {
                $field->setValue($this->values[$field->getFieldName()]);
            } elseif($default !== null) {
                $this->values[$field->getFieldName()] = $default;
                $field->setValue($default);
            }
			$this->fields[$field->getName()] = $field;

			return $field;
		}

        /**
         * Adds an array of fields to this fieldset by calling addField() on each field.
         *
         * @param ARRAY $fields Array of field objects to add
         * @return VOID
         */
		function addFields(array $fields) {
			foreach($fields as $field) {
				$this->addField($field);
			}
        }

        /**
		 * Adds a row manager that the fields in this fieldset can use to interface with the database.
		 *
		 * @param OBJECT $dbRow The database row manager object of type RowManager to add.
		 * @return VOID
		 */
		function addRowManager(RowManager $dbRow) {
			$this->dbRows[] = $dbRow;
            //if this is an add type form, what new information could the database possibly give us?
            if($this->formType != Form::ADD) {
                $this->values = $this->getDBValues();
                foreach($this->fields as $field) {
                    $field->setValue($this->values[$field->getName()]);
                }
            }
		}

        /**
         * Updates the database with values generated during the process stage.
         *
         * If the row is empty and error suppression is on, the commit succeeds, though nothing
         * actually happens.
         *
         * @return BOOLEAN False if an error was encountered updating the database.
         */
        final function commit() {
            if($this->isEmpty() && $this->silent) {
                return true;
            }
			foreach($this->fields as $field) {
				$field->databasePrep();
			}
            //refetch values from fields to allow for custom scenarios
            foreach($this->fields as $field) {
                if(is_array($field->getValue())) { //handle password fields, etc
                    $this->values = array_merge($this->values, $field->getValue());
                } else {
                    $this->values[$field->getName()] = $field->getValue();
                }
            }
            //hand off to the db row
            foreach($this->dbRows as $dbRow) {
                $dbRow->setValues($this->values);
                if(!$dbRow->finalize($this->formType)) {
                    if(!isset($_POST["errors"])) {
                        print "<br>Error: <u>Please</u> contact your system administrator!<br>";
                    } else {
                        foreach($_POST["errors"] as $name=>$err) {
                            $this->fields[$name]->appendDBErrors();
                        }
                    }
                    if($this->formType == Form::DELETE) {
                        print "<font color='red'><b>Please</b> don't do <i>anything</i>
                        until your system administrator tells you everything is ok again.</b></font><br>";
                    }
                    return false;
                }
            }
            //reload db values (to update fields like autoincrementing keys))
            $this->init();
            //push db values back out to the fields
            foreach($this->fields as $field) {
                $field->setValue($this->values[$field->getName()]);
            }
			return true;
		}

        /**
		 * Displays a form's row data as HTML.
		 *
		 * @return VOID
		 */
		abstract function display();

        /**
         * Returns an array of all the fields currently managed by this fieldset.
         *
         * @return ARRAY List of field objects
         */
		function getFields() {
			return $this->fields;
		}

        /**
         * Returns the name of the first database table in the list.
         *
         * @return STRING A database table name associated with these fields.
         */
		function getTableName() {
			return $this->dbRows[0]->getTableName();
		}

        /**
         * Returns the current value of the given field (as understood by the database).
         *
         * @param STRING $field The name of the field to look up.
         * @return STRING The database's understanding of the given fields current value.
         */
		function getValue($field) {
			return $this->values[$field];
        }

        /**
         * Returns the internal values array.
         *
         * @return ARRAY Array of field values.
         */
        function getValues() {
            return $this->values;
        }

        /**
         * Fetches an array of key-value pairs of the form [fieldName]->value
         * from the database.
         * @return ARRAY Array of values in the database.
         */
        function getDBValues() {
            $ret = array();
            $tmp = array_fill_keys(array_keys($this->fields), "");
            foreach($this->dbRows as $row) {
                $ret = array_merge($row->getValues($tmp), $ret);
            }
            return $ret;
        }

        /**
		 * Checks to see if the form this fieldset is in is an add type form.
		 *
		 * @return BOOLEAN True if the form is an add form.
		 */
		function isAdd() {
			return $this->formType == Form::ADD;
		}

        /**
         * Returns true if none of the fields (except Keys and ForeignKeys) have data.
         *
         * @return BOOLEAN False if a field (not a Key or ForeignKey) has a value.
         */
        function isEmpty() {
            return $this->isEmpty;
        }

        /**
         * Initializes the internal values and field values from the database
         *
         * @return VOID
         */
        function init() {
        	//the database might not manage some of the form fields,
        	//so this addition retains them.
        	//NOTE: array_merge() will reorder numerical keys. DON'T USE IT
            $this->values = $this->getDBValues() + $this->values;
            if(!isset($_REQUEST["update"])) {
                foreach($this->values as $field=>$value) {
                    if(is_object($this->fields[$field])) { //ignore psuedo-fields like password_salt
                        $this->fields[$field]->setValue($value);
                    }
                }
            }
        }

        /**
		 * Processes all the fields in this fieldset.
         *
         * Error suppression (silent mode) is also controlled here. If silent mode is enabled
         * and a field (not a Key or ForeignKey) is not empty, silent mode is disabled for the
         * fieldset and for all fields in this fieldset.
         * Also note that the database is not altered in any way by this process.
		 *
		 * @return BOOLEAN False if this form had errors.
		 */
		final function process() {
			$success = true;
			if(isset($_POST["submit"]) || isset($_POST["update"])) {
                $values = $this->getDBValues();
				foreach($this->fields as $field) {
                    if(!isset($_REQUEST[$field->getFieldName()])) {
                        $field->setValue($values[$field->getName()]);
                    }
                    $success = $field->process() && $success;
                    if(is_array($field->getValue())) { //handle password fields, etc
                        $this->values = array_merge($this->values, $field->getValue());
                    } else {
                        $this->values[$field->getName()] = $field->getValue();
                    }
                    if(!$field->isKey()) {
                        $empty = $field->isEmpty() || $empty;
                    }
                }
                //if one of the fields had data, turn off error suppression
                if(!$empty) {
                    foreach($this->fields as $field) {
                        $field->setSilent(false);
                    }
                }
                $this->isEmpty = $empty;
			} else {
				//the form has not been submitted
				$success = false;
			}

			return $success || ($this->isEmpty() && $this->silent);
		}

        /**
		 * Sets the type of the form this fieldset is in
         *
         * @param INTEGER $formType The form this fieldset is part of.
         * @return VOID
		 */
        function setFormType($formType) {
            $this->formType = $formType;
        }

        /**
         * Provides a friendly name for this class for error messages.
         *
         * @return STRING class name.
         */
		function __toString() {
			return "Fieldset";
		}
	}
?>
