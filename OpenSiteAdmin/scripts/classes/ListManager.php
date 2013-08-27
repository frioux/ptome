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
	 * Manages processing and display for lists based on a row's database information.
	 *
	 * @author John Oren
	 * @version 1.1 July 31, 2008
	 */
	class ListManager {
		/** @var Array of filters to apply to the database list. */
		protected $filters;
		/** @var Array of filter hooks to filter the database results. */
		protected $filterHooks;
		/** @var name of the database column to use in a SQL ORDER BY clause to apply to the database list. */
		protected $order;
        /** @var The direction (asc\desc) to sort by. */
        protected $sortDir;

		/**
		 * Constructs a new list (does not initiate any display or processing).
		 */
		function __construct() {
			$this->filters = array();
			$this->filterHooks = array();
			$this->order = null;
            $this->sortDir = "asc";
		}

		/**
		 * Adds a filter to the list being displayed.
		 *
		 * @param OBJECT $filter The object of type Filter to add.
		 * @return VOID
		 */
		function addFilter(Filter $filter) {
			$this->filters[] = $filter;
        }

		function addFilterHook($hook) {
			$this->filterHooks[] = $hook;
		}

        /**
		 * Generates forms from any filters that may be applied to this form.
		 *
		 * @param ARRAY $filters Array of filters to generate forms for.
		 * @param ARRAY $data Form data to use to populate filter data.
		 * @return STRING HTML form to use for filtering the list.
		 */
		protected function generateFilterForms($filters, $data) {
			if(count($filters) == 0) {
				return "";
			}
			$ret = '<form method="post" action="">';

			foreach($filters as $filter) {
				if($data) {
					$filter->setDefaultValue(array_shift($data));
				}
				$ret .= $filter->getForm()."<br>";
			}

			$ret .= '<input type="submit" name="filter" value="Apply Filter';
			if(count($this->filters) > 1) {
				$ret .= 's';
			}
			$ret .= '">';
			$ret .= '</form>';

			return $ret;
		}

		/**
		 * Generates and returns a list (HTML table) of data using the given row as a template.
		 *
		 * @param OBJECT $fieldset Fieldset object to use as a template for fields and field titles.
         * @param OBJECT $keyField The primary key field for the provided fieldset.
		 * @param OBJECT $linkField The database field to use as a link to allow for editing\deleting a particular field.
		 * @param STRING $QS Any text to apply to the end of links. An '&' is prepended to this if it is not empty.
		 * @param ARRAY $data Form data from filter forms.
		 * @return STRING HTML Table containing the list data.
		 */
		function generateList(Fieldset $fieldset, Field $keyField, Field $linkField, $QS, $data=null) {
			if(!empty($QS)) {
				$QS = "&".$QS;
			}

			$fields = $fieldset->getFields();
			$ret = $this->generateFilterForms($this->filters, $data);

			$where = Filter::getFilterClause($this->filters);
			$order = "";
			if(!empty($this->order)) {
				$order = "ORDER BY `".$this->order."` ".$this->sortDir;
			}

            $result = DatabaseManager::checkError("select * from `".$fieldset->getTableName()."` ".$where." ".$order);

			$ret .= '<table id="sortable-table-0" class="sortable full">';
			//add list headers
            $ret .= '<thead>';
			$ret .= '<tr>';
			foreach($fields as $field) {
				if($field->isInList()) {
					$ret .= '<th class="sortcol">'.$field->getTitle(true).'</th>';
				}
			}
			$ret .= '</tr>';
            $ret .= '</thead>';

            $ret .= '<tbody>';
			//add list data
			while($entry = DatabaseManager::fetchAssoc($result)) {
				$showRow = true;
				foreach($this->filterHooks as $filterHook) {
					if(!$filterHook->process($entry)) {
						$showRow = false;
						break;
					}
				}
				if(!$showRow) {
					continue;
				}
				$ret .= "<tr>";
				foreach($fields as $field) {
					if(!$field->isInList()) {
						continue;
					}
					$ret .= "<td>";
					$val = $field->getListView($entry[$field->getName()]);
					if($field->getFieldName() == $linkField->getFieldName()) {
						$ret .= '<a href="?id='.$entry[$keyField->getName()].$QS.'">'.$val.'</a>';
					} else {
						$ret .= $val;
					}
					$ret .= "</td>";
				}
				$ret .= "</tr>";
			}
            $ret .= '</tbody>';

			$ret .= '</table>';
			return $ret;
		}

		/**
		 * Sets the MySQL ORDER BY clause (The phrase "ORDER BY" is automatically included).
		 *
		 * @param STRING $order Name of the column to order the display by.
		 * @param BOOLEAN $ascending Sorts ascending if true
		 * @return VOID
		 */
		function setOrderBy($order, $ascending=true) {
			$this->order = $order;
            $this->sortAscending($ascending);
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
	}
?>
