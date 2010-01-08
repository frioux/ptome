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

	require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");

	/**
	 * Allows SQL statements to be filtered by a single value in a single field.
	 *
	 * @author John Oren
	 * @version 1.0 December 30, 2007
	 */
    class SingleFilter extends Filter {
        /** @var The value of the search field to filter by. */
        private $defaultValue;
        /** @var The name of the field to use for display in a form field. */
		private $displayField;
		/** @var The name of the field to search OR the name of the field to use as a key if this filter is used as a form. */
		private $field;
		/** @var The name of the database table used to populate form options. */
		private $tableName;

		/**
		 * Constructs a filter for a single MySQL Field
		 *
		 * @param STRING $field The field to filter by.
		 * @param MIXED $defaultValue The value to search for in the given field. Set to null for no filter effect.
		 * @param STRING $table The name of the database table this filter should pull data from for form display.
		 * @param STRING $displayField The field used for display in the filter form.
		 */
		function __construct($field, $defaultValue, $table=null, $displayField=null) {
			if(empty($table) xor empty($displayField)) {
				die("Error in ".$field.": If a single filter defines either a tablename or a primary key field, it must define both");
			}
			$this->field = $field;
			$this->defaultValue = $defaultValue;
			$this->tableName = $table;
			$this->displayField = $displayField;
		}

		/**
		 * This type of filter does not have a form.
		 * Note that filter forms must define multiple field values as an array of values.
		 *
		 * @param ARRAY $filters Array of Filter objects to use to filter a SQL query to get data for this form.
		 * @param MIXED $data Optional data to use in this form.
		 * @return STRING Error message.
		 */
		function getForm(array $filters=null, $data=null) {
			if(!is_array($data)) {
				if(empty($this->tableName)) {
					return "This form has no data and no table to pull data from";
				}
				$whereClause = Filter::getFilterClause($filters);
				$result = DatabaseManager::checkError("select `".$this->field."`,`".$this->displayField."` from `".$this->tableName."`".$whereClause);
				while($row = DatabaseManager::fetchArray($result)) {
					$data[$row[0]] = $row[1];
				}
			}

			$form = 'Filter By Category:&nbsp;
				<select name="'.$this->field.'">
					<option value=""';
					if($this->defaultValue < 0) {
						$form .= ' selected';
					}
					$form .= '>All</option>';
					foreach($data as $key=>$val) {
						$form .= '<option value="'.$key.'"';
						if($key == $this->defaultValue) {
							$form .= ' selected';
						}
						$form .= '>'.$val.'</option>';
					}
				$form .= '</select>';

			return $form;
		}

		/**
		 * Returns a formatted MySQL WHERE clause.
		 *
		 * @return STRING Formatted string for use in a MySQL query
		 */
		function getWhereClause() {
			if($this->defaultValue === null) {
				return "1";
			}
			return "`".$this->field."` = '".$this->defaultValue."'";
		}

		/**
		 * Returns whether or not this filter has a value to use to alter a database query.
		 *
		 * @return STRING True if this field can create a meaningful where clause
		 */
		function isEmpty() {
			return empty($this->defaultValue);
		}

		/**
		 * Sets the default value for this filter. Intended for use with this filter's form.
		 *
		 * @param MIXED $value The value to use for this filter's where clause. Set to null for no filter effect.
		 * @return VOID
		 */
		function setDefaultValue($value) {
			if(strlen($value) == 0) {
				$value = null;
			}
			$this->defaultValue = $value;
		}
	}
?>
