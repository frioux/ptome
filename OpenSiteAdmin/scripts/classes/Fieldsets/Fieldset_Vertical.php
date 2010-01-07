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
	 * Handles display and processing for a single row form.
	 *
	 * This form displays the fields for a single row in a verticla format.
	 * Field titles are shown to the left of each element with each field on it's
	 * own line. All titles and fields are left-aligned.
	 * This form type does not use the form's optional parameter.
	 *
	 * @author John Oren
	 * @version 1.1 August 4, 2008
	 */
	class Fieldset_Vertical extends Fieldset {
		/**
		 * Displays this form's row fields in a vertical HTML form.
		 *
		 * @return VOID
		 */
		function display() {
            if(empty($this->values)) {
                $this->init();
            }
			print '<table>';
			foreach($this->fields as $field) {
                if(!$field instanceof Hidden) {
                    print '<tr>';
                    if($this->showLabels) {
                        print '<td>'.$field->getTitle().'</td>';
                    }

                    print '<td>'.$field->display().'</td>';
                    print '</tr>';
                } else {
                    print $field->display();
                }
			}
			print '</table>';
		}
	}
?>
