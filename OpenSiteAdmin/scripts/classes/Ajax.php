<?php
    /*
	 *	Copyright 2009 John Oren
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

    require_once($path."OpenSiteAdmin/scripts/classes/Ajax/Ajax_Autocomplete.php");

    /**
	 * Defines a template for displaying Ajax on form fields.
	 *
	 * @abstract
	 * @author John Oren
	 * @version 1.0 December 24, 2009
	 */
    abstract class Ajax {
        /** @var The name of the field this Ajax object is associated with. */
        protected $fieldName;

        /**
         * Displays the Ajax and any related code immediately after the field is displayed.
         *
         * @return STRING
         * @abstract
         */
        abstract function display();

        /**
         * Sets the name of the field this object is associated with.
         *
         * @param STRING Field name.
         * @return VOID
         */
        function setFieldName($fieldName) {
            $this->fieldName = $fieldName;
        }
    }
?>