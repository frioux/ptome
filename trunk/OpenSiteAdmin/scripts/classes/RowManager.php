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

    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");
	require_once($path."OpenSiteAdmin/scripts/classes/Filter.php");
	require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."OpenSiteAdmin/scripts/classes/SecurityManager.php");

	/**
	 * Handles database interaction with a row in a MySQL database table.
	 *
	 * @author John Oren
	 * @version 1.6 January, 2009
	 */
    class RowManager {
        /** @var Array of filters to apply to any query. */
        protected $filters;
        /** @var True if $values has been initialized with data from the database or from the form. */
        protected $hasValues;
        /** @var The database field name to order results by. */
		protected $orderBy;
        /** @var Value of the primary key for this row. */
        protected $primaryKeyName;
        /** @var The direction (asc\desc) to sort by. */
        protected $sortDir;
        /** @var The name of the database table this row is in. */
        protected $tableName;
        /** @var True if $values contains data that is different than what is in the database. */
		protected $updated;
        /** @var Array of key-pair values in the form $values[fieldName] = value. */
		protected $values;

		/**
		 * Constructs a new row manager with no fields, a unique ID, and the given data.
		 *
		 * @param STRING $tableName Name of the table this row corresponds to.
		 * @param STRING $primaryKeyName The name of the primary key field for this table.
		 * @param INTEGER $primaryKey The value of the primary key for this row (if any)
		 */
		function __construct($tableName, $primaryKeyName, $primaryKey=-1) {
            $this->tableName = $tableName;
			$this->primaryKeyName= $primaryKeyName;
            $this->values = array();

			$this->updated = false;
			$this->filters = array();
			$this->orderBy = $this->primaryKeyName;
            $this->sortDir = "asc";

            if($primaryKey != -1) {
                $this->values[$primaryKeyName] = $primaryKey;
            }
            $this->initialize();
        }

        /**
         * Adds the given filter to the internal list of query filters.
         *
         * @param OBJECT $filter The filter object to add.
         * @param BOOLEAN $group Set to true to disable reinitialization. Used for optimizing
         *                imports of lists of filters.
         * @return VOID
         */
		function addFilter(Filter $filter, $group=false) {
			$this->filters[] = $filter;
			if(!$group) {
				$this->initialize();
			}
        }

        /**
         * Adds the given list of filters to the internal list of query filters.
         *
         * @param ARRAY $filters List of filters to add.
         */
		function addFilters(array $filters) {
			foreach($filters as $filter) {
				$this->addFilter($filter, true);
			}
			$this->initialize();
		}

        /**
		 * Deletes this row from the database.
		 *
		 * @return BOOLEAN False if errors where encountered in any field or in processing the form.
		 */
		protected function delete() {
			if($this->getPrimaryKeyValue() == null) {
				print "There was an error processing this form.<br>";
				$msg = "Error: attempted to update a database row with no primary key set";
				ErrorLogManager::log($msg, ErrorLogManager::FATAL);
				return false;
			}

			$where = Filter::getFilterClause($this->getFilters());
			$query = "delete from `".$this->getTableName()."` $where";
			return DatabaseManager::checkError($query) !== false;
		}

		/**
		 * Updates the current data to the database, adding, inserting, or deleting as necessary.
		 *
		 * @param INTEGER The type of this form for deciding whether to add, update, or delete.
		 * @return BOOLEAN False if an error is encountered.
		 */
        function finalize($type) {
            //this if statement doesn't allow for the delete case.
            //is this an optimization of edit, or is there some good reason for this??
            if($this->hasValues) {
                if($this->getPrimaryKeyValue() == null) {
					return $this->insert();
				} else {
					return $this->{RowManager::getModeText($type)}();
				}
			} else {
				return true;
			}
        }

        /**
         * Returns an array of all the filters associated with this object. If a primary key
         * value has been set for this row, the primary key filter is added to the list of filters.
         *
         * @return ARRAY List of filter objects.
         */
		protected function getFilters() {
			$filters = $this->filters;
			if($this->getPrimaryKeyValue() != null) {
				$filters[] = $this->getPrimaryKeyFilter();
			}
			return $filters;
        }

        /**
         * Returns the last number used in an autoincrement field in this table.
         *
         * @return INTEGER Last insert ID number (usually the primary key)
         */
		protected function getLastInsertID() {
			return DatabaseManager::getInsertID(DatabaseManager::getLink());
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
					return "insert";
				case Form::EDIT:
					return "update";
				case Form::DELETE:
					return "delete";
				default:
					print "A fatal error occured.<br>";
					$error = "ERROR: Attempted to generate a form of unknown type $mode.<br>";
					die(ErrorLogManager::log($error, ErrorLogManager::FATAL));
			}
		}

        /**
		 * Returns a filter to limit a query to data pertaining to this row.
		 *
		 * @return OBJECT Filter object.
		 */
		protected function getPrimaryKeyFilter() {
			if($this->getPrimaryKeyValue() == null) {
				return null;
			}
			return new SingleFilter($this->getPrimaryKeyName(), $this->getPrimaryKeyValue());
		}

		/**
		 * Returns the name of the primary key field for the table this row interacts with.
		 *
		 * @return STRING Primary key field name.
		 */
		function getPrimaryKeyName() {
			return $this->primaryKeyName;
        }

        /**
         * Returns the value of this row's primary key.
         *
         * @return MIXED Primary key value.
         */
        protected function getPrimaryKeyValue() {
            return $this->values[$this->getPrimaryKeyName()];
        }

        /**
         * Returns a list of row managers for all the rows in this row manager's table matching
         * the current filters.
         *
         * It is highly recommended, but not required, that the user apply filters to this row
         * manager before executing this method.
         *
         * @return ARRAY List of all row managers, one for each database row matching the query.
         */
		function getRowManagers() {
			$ret = array();

			$where = Filter::getFilterClause($this->filters);
			$sql = "select * from `".$this->getTableName()."` $where order by `".$this->orderBy."` ".$this->sortDir;
			$result = DatabaseManager::checkError($sql);

			while($entry = DatabaseManager::fetchAssoc($result)) {
				$i++;
				$ret[] = new RowManager($this->tableName, $this->getPrimaryKeyName(), $entry[$this->getPrimaryKeyName()]);
			}

			return $ret;
		}

		/**
		 * Returns the name of the database table this row interacts with.
		 *
		 * @return STRING Name of this row's database table.
		 */
		function getTableName() {
			return $this->tableName;
		}

        /**
         * Returns the most recently available value for the given field ready for form display.
         *
         * @param STRING $fieldName The name of the database field.
         * @return MIXED The value of this field in memory
         */
		function getValue($fieldName) {
			return SecurityManager::formPrep($this->values[$fieldName]);
        }

        /**
         * Returns the most recently available value for the given fields ready for form display.
         *
         * @param ARRAY $fieldNames An array keyed by the names of database fields.
         * @return ARRAY The given array with populated values.
         */
        function getValues(array $fieldNames) {
            if(empty($this->values)) {
                //return an array with the same keys and null values
                return array_combine(array_keys($fieldNames), array_fill(0, count($fieldNames), null));
            }
            foreach($fieldNames as $key=>$val) {
                if(array_key_exists($key, $this->values)) {
                    $fieldNames[$key] = $this->getValue($key);
                } else {
                    unset($fieldNames[$key]);
                }
            }
            return $fieldNames;
        }

        /**
		 * Initializes the array of values currently in the database for this row (if any).
		 *
		 * @return VOID
		 */
		protected function initialize() {
            if(!empty($this->values)) { //don't look for values if a primary key value is not set
                $this->hasValues = true;
                $where = Filter::getFilterClause($this->getFilters());
                $sql = "select * from `".$this->getTableName()."` $where order by `".$this->orderBy."` ".$this->sortDir;

                $result = DatabaseManager::checkError($sql);
                $this->values = DatabaseManager::fetchAssoc($result);
            }
            if(empty($this->values)) {
                $result = DatabaseManager::checkError("SHOW COLUMNS FROM `".$this->getTableName()."`");
                $this->values = array();
                while($col = DatabaseManager::fetchAssoc($result)) {
                    $this->values[$col["Field"]] = null;
                }
                $this->hasValues = false;
			}
        }

        /**
		 * Inserts the current set of values into the database.
		 *
		 * @return BOOLEAN False if errors where encountered in any field or in processing the form.
		 */
		protected function insert() {
			$names = "";
			$values = "";
			foreach($this->values as $name=>$value) {
				$names .= "`".$name."`,";
				$values .= "'".$value."',";
			}
			$names = substr($names, 0, strlen($names)-1);
			$values = substr($values, 0, strlen($values)-1);
			$query = "insert into `".$this->getTableName()."` (".$names.") values (".$values.")";
			$ret = DatabaseManager::checkError($query) !== false;
			if($ret) {
				$this->setValue($this->primaryKeyName, $this->getLastInsertID(), false);
			}
			return $ret;
        }

        /**
         * Sets the field name results should be ordered by.
         *
         * @param STRING $orderBy The name of the database field to order by.
         * @param BOOLEAN $ascending Sorts ascending if true
         * @return VOID
         */
		function setOrderBy($orderBy, $ascending=true) {
			$this->orderBy = $orderBy;
            $this->sortAscending($ascending);
		}

        /**
         * Sets the current local value for the given fieldname.
         *
         * @param STRING $fieldName Name of the database field.
         * @param MIXED $value The value to set.
         * @param BOOLEAN $update If false, $this->updated is not altered.
         *                        This is useful for fields like foreign keys that do not provide
         *                        any new information unique to the row.
         * @return VOID
         */
		function setValue($fieldName, $value, $update=true) {
			$value = SecurityManager::SQLPrep($value);
			if($this->getValue($fieldName) != $value) {
                if(!$this->updated && $update && $this->values[$fieldName] != $value) {
                    $this->updated = true;
                }
                $this->hasValues = true;
				$this->values[$fieldName] = $value;
			}
		}

        /**
         * Sets the internal value array using the given values if the array key (corresponding
         * to the column name) is a column associated with this row manager
         *
         * @param ARRAY $values Associative array of column=>value data
         * @return VOID
         */
        function setValues(array $values) {
            $this->hasValues = !empty($values);
            foreach($values as $field=>$value) {
                if(array_key_exists($field, $this->values)) {
                    $this->setValue($field, $value);
                }
            }
        }

        /**
         * Changes the sort order of results
         *
         * @param BOOLEAN $yes Sorts ascending if true
         * @return VOID
         */
        function sortAscending($yes) {
            if($yes) {
                $this->sortDir = "asc";
            } else {
                $this->sortDir = "desc";
            }
        }

		/**
		 * Updates the database with the current set of values if any changes have been made.
		 *
		 * @return BOOLEAN False if errors where encountered in any field or in processing the form.
		 */
		protected function update() {
			//no point in updating if nothing changed...
            if(!$this->updated) {
                return true;
            }
            if($this->getPrimaryKeyValue() == null) {
				print "There was an error processing this form.<br>";
				$msg = "Error: attempted to update a database row with no primary key set";
				ErrorLogManager::log($msg, ErrorLogManager::FATAL);
				return false;
			}

			$set = "";
			foreach($this->values as $name=>$value) {
				$set .= "`".$name."` = '".$value."',";
			}
			$set = substr($set, 0, strlen($set)-1);
			$where = Filter::getFilterClause($this->getFilters());
			$query = "update `".$this->getTableName()."` set $set $where";
            return DatabaseManager::checkError($query) !== false;
		}

        /**
         * Returns the name of this class (for debug messages).
         *
         * @return STRING Class name.
         */
        function __toString() {
            return "RowManager - ".$this->getTableName();
        }
	}
?>