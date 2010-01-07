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
	 * Handles display and processing for a list-style form.
	 *
	 * @author John Oren
	 * @version 1.1 August 4, 2008
	 */
	class Fieldset_Horizontal extends Fieldset {
		/**
		 * Displays this form's row fields in a horizontal HTML form.
		 *
		 * @return VOID
		 */
		function display() {
            if(empty($this->values)) {
                $this->init();
            }
			print '<table>';
			if($this->showLabels) {
				print '<tr>';
				foreach($this->fields as $field) {
					print '<td>'.$field->getTitle().'</td>';
				}
				print '</tr>';
			}

			print '<tr>';
			foreach($this->fields as $field) {
				print '<td>'.$field->display().'</td>';
			}
			print '</tr>';

			print '</table>';
		}

        /**
         * Generates multiple rows as a group.
         *
         * Displays multiple copies of a single row in a list-style format. All rows must be part of the
         * same database table. Titles for each field are shown above all the rows, with each row
         * following on its own line. This form makes use of the form's optional parameter by adding the
         * specified number of extra empty rows to the end of the list. If this field is left blank or 0,
         * no extra rows are added.
         *
         * @param OBJECT $iterator The row manager to use as a template for all rows.
         * @param ARRAY $fields Array of field objects (database fields) to include in the form.
         * @param OBJECT $form Form object these fieldsets will belong to.
         * @param INTEGER $numExtraRows The number of blank rows to display.
         * @return ARRAY List of HorizontalFieldsets.
         */
		static function generate(RowManager $iterator, $fields, Form $form, $numExtraRows=0) {
			$ret = array();
			$mgrs = $iterator->getRowManagers();

            //add a row for each fieldset that's actually managed currently
			$showLabels = true;
			foreach($mgrs as $mgr) {
				$fieldset = new Fieldset_Horizontal($form->getFormType(), $showLabels);
				$showLabels = false;
				foreach($fields as $field) {
					$fieldset->addField(clone $field);
				}
				$fieldset->addRowManager($mgr);
				$ret[] = $fieldset;
			}

            //add extra blank rows and handle update calls to add new blank rows
			for($i = 0; $i < $numExtraRows; $i++) {
				$fieldset = new Fieldset_Horizontal($form->getFormType(), $showLabels, true);
				$showLabels = false;
				$keyField = null;
				foreach($fields as $field) {
					$field = clone $field;
					$fieldset->addField($field);
					if($field->getName() == $iterator->getPrimaryKeyName()) {
						$keyField = $field;
					}
				}
				if(empty($keyField)) {
					die("BIG ERROR - no key field!<br>");
				}
                $keyField->setKey();
				$fieldset->addRowManager(new RowManager($iterator->getTableName(), $keyField->getName()));
                //if this fieldset processes and is not empty, we updated and need a new blank row
                if($fieldset->process() !== false && !$fieldset->isEmpty()) {
                    $numExtraRows++;
                }

				$ret[] = $fieldset;
			}

			return $ret;
		}
	}
?>
