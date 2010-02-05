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

    /**
	 * Displays an dropdown list on a field that offers completions to what the user is entering.
	 *
	 * @author John Oren
	 * @version 1.0 December 24, 2009
	 */
    class Ajax_AutoComplete extends Ajax {
        /** @var The name of the file data from the field should be posted to for a list of completions. */
        protected $callback;
        /** @var The frequency (in seconds) that the field should try to fetch updates. */
        protected $frequency;
        /** @var The minimum number of characters that must be typed before searching for completions. */
        protected $minChars;
        /** @var The name of the function to call after an element is selected. */
        protected $callbackFunction;

        /**
         * Constructs the object.
         *
         * @param STRING $callback Name of the file to post partial data to for completion.
         * @param INT $minChars Minimum number of characters before searching for completions.
         * @param FLOAT $frequency Frequency in seconds to update the completion list.
         */
        function __construct($callback, $minChars, $frequency=0.2) {
            $this->callback = $callback;
            $this->minChars = $minChars;
            $this->frequency = $frequency;
        }

        /**
         * Sets the name of the function to call after an element is selected from the completion list
         *
         * @param STRING $function Function name.
         * @return VOID
         */
        function setCallbackFunction($function) {
            $this->callbackFunction = $function;
        }

        /**
         * Displays the Ajax and any related code immediately after the field is displayed.
         *
         * @return STRING
         */
        function display() {
            $ret = '<div class="auto_complete" id="'.$this->getName().'"></div>
                <script type="text/javascript">
                    <!--';
            $ret .= "\nnew Ajax.Autocompleter( '".$this->fieldName."', '".$this->getName()."', '".$this->callback."', {frequency:".$this->frequency.", minChars:".$this->minChars;
            if(!empty($this->callbackFunction)) {
                $ret .= ", afterUpdateElement:".$this->callbackFunction;
            }
            $ret .= "} )
                    //-->
                </script>";
            return $ret;
        }

        /**
         * Returns the id of the autocomplete container.
         *
         * @return STRING
         */
        function getName() {
            return $this->fieldName.'_auto_complete';
        }
    }
?>