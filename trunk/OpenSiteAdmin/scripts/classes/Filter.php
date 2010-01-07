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


	//include all of the standard filters
	require_once($path."OpenSiteAdmin/scripts/classes/Filters/SingleFilter.php");

	/**
	 * Defines a template for creating filters to generate SQL WHERE clauses.
	 *
	 * @abstract
	 * @author John Oren
	 * @version 1.1 August 5, 2008
	 */
    abstract class Filter {
        /**
		 * Creates the MySQL where clause from all the given filters.
		 *
		 * @param ARRAY $filters Filters to use in constructing the where clause.
		 * @return STRING MySQL where clause or an empty string if no filters were specified.
		 */
		static final function getFilterClause(array $filters=null) {
			if(count($filters) == 0)
				return "";
			$ret = " WHERE ";

			foreach($filters as $filter) {
				$ret .= $filter->getWhereClause()." AND ";
			}
			$ret = substr($ret, 0, -5); //remove the trailing AND

			return $ret;
		}

		/**
		 * Returns an HTML form for display a filter for a list.
		 * Note that filter forms must define multiple field values as an array of values.
		 *
		 * @param ARRAY $filters Array of Filter objects to use to filter a SQL query to get data for this form.
		 * @param MIXED $data Optional data to use in this form.
		 * @return STRING HTML to display for the filter form.
		 * @abstract
		 */
		abstract function getForm(array $filters=null, $data=null);

		/**
		 * Returns a formatted MySQL WHERE clause.
		 *
		 * @return STRING Formatted string for use in a MySQL query
		 * @abstract
		 */
		abstract function getWhereClause();

		/**
		 * Returns whether or not this filter has a value to use to alter a database query.
		 *
		 * @return BOOLEAN True if this field can create a meaningful where clause
		 * @abstract
		 */
		abstract function isEmpty();

		/**
		 * Sets the default value for this filter.
		 *
		 * @param MIXED $value The value or values to use for this filter's where clause
		 * @return VOID
		 * @abstract
		 */
		abstract function setDefaultValue($value);
	}
?>
