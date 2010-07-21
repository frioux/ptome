<?php
    require_once($path."OpenSiteAdmin/scripts/classes/Fields/Text.php");

    /**
	 * Handles display and processing of a Text field designed specifically to process LETU emails.
	 *
	 * OPTIONAL<br>
	 * $options["size"] - size of the form's text input field<br>
	 * $options["maxlength"] - maximum length of text input field<br>
	 */
    class LETUEmailField extends Text {
        /**
		 * Processes this field and update the backend used by this field.
		 *
		 * Validates if the input is a LETU email address.
		 *
		 * @return BOOLEAN False if errors were encountered
		 */
        function process() {
            $ret = parent::process();
            $value = $this->getValue();
            if($value == null) {
               return $ret;
            } elseif(!strchr($value, "@")) {
                $value .= "@letu.edu";
                $this->setValue($value);
            } elseif(substr($value, -9) != "@letu.edu") {
                $this->errorText .= "Email must be a LeTourneau address";
                return false;
            }
            return $ret;
        }
    }
?>
